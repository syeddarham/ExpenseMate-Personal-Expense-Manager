#!/usr/bin/env node
/**
 * Local demo server for the Assignment 02 presentation.
 *
 *   npm run demo                                        empty database
 *   npm run demo -- Database/dump/expensemate_db.sql    copy of real data, migrated live
 *
 * Starts a throwaway MySQL, (optionally) imports a dump, runs the
 * migrations, then serves the API on http://localhost:5000/api with e-mail
 * disabled: verification/reset codes are printed in this terminal.
 * Point the app at it with:
 *   flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
 * (Android emulator: http://10.0.2.2:5000/api)
 */
const fs = require('fs');
const path = require('path');
const { startMysql } = require('../tests/helpers/mysql');

const PORT = Number(process.env.DEMO_PORT || 5000);

async function main() {
  const dumpFile = process.argv[2];
  console.log('[demo] Starting throwaway MySQL (first run downloads it once)...');
  const mysql = await startMysql();
  const db = await mysql.createDatabase('demo');

  if (dumpFile) {
    console.log(`[demo] Importing ${path.basename(dumpFile)} ...`);
    const conn = await mysql.connect(db);
    await conn.query(fs.readFileSync(dumpFile, 'utf8'));
    await conn.end();
  }

  // Configure everything explicitly BEFORE src/config/env loads, so values
  // from a real Backend/.env (production DB, SMTP) can never be used here.
  Object.assign(process.env, {
    NODE_ENV: 'development',
    PORT: String(PORT),
    DB_HOST: db.host,
    DB_PORT: String(db.port),
    DB_USER: db.user,
    DB_PASSWORD: db.password,
    DB_NAME: db.name,
    AUTO_INIT_DB: 'true',
    JWT_SECRET: 'local-demo-secret',
    JWT_EXPIRES_IN: '1d',
    SMTP_HOST: '',
    SMTP_PORT: '',
    SMTP_USER: '',
    SMTP_PASS: '',
    SMTP_FROM: '',
  });
  const env = require('../src/config/env');
  const { Migrator } = require('../src/database/migrator');
  const { buildContainer } = require('../src/container');
  const { createApp } = require('../src/app');

  const migrator = new Migrator({ db: env.db });
  console.log('[demo] Migration status before:', (await migrator.status()).map((m) => `${m.version}:${m.applied ? 'applied' : 'pending'}`).join(' '));
  await migrator.up();

  const container = buildContainer({ env });
  const server = createApp(container).listen(PORT, () => {
    console.log(`[demo] ExpenseMate API on http://localhost:${PORT}/api  (Ctrl+C to stop; data is discarded)`);
  });

  const shutdown = async () => {
    server.close();
    await container.pool.end();
    await mysql.stop();
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main().catch((err) => {
  console.error('[demo] Failed:', err);
  process.exit(1);
});
