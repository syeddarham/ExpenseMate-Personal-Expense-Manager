#!/usr/bin/env node
/**
 * Migration rehearsal: runs the real migration CLI against a COPY of a
 * production dump on a throwaway local MySQL server, and verifies that
 * every existing record survives unchanged.
 *
 *   node scripts/rehearse-migration.js Database/dump/expensemate_db.sql
 *
 * Steps: start MySQL -> import dump -> status -> snapshot -> migrate ->
 *        status -> verify -> migrate again (idempotency check).
 * Output contains only counts and hashes (no personal data).
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { startMysql } = require('../tests/helpers/mysql');

const BACKEND = path.join(__dirname, '..');

async function main() {
  const dumpFile = process.argv[2];
  if (!dumpFile || !fs.existsSync(dumpFile)) {
    console.error('Usage: rehearse-migration.js <dump.sql>');
    process.exit(2);
  }

  console.log(`== Starting throwaway MySQL server`);
  const mysql = await startMysql();
  try {
    const db = await mysql.createDatabase('rehearsal');
    console.log(`== Importing ${path.basename(dumpFile)} (${(fs.statSync(dumpFile).size / 1024).toFixed(0)} KB) into ${db.name}`);
    const conn = await mysql.connect(db);
    await conn.query(fs.readFileSync(dumpFile, 'utf8'));
    await conn.end();

    // Every DB_* variable is set explicitly so the CLIs can never fall back
    // to values from a real Backend/.env (dotenv does not override them).
    const env = {
      PATH: process.env.PATH,
      HOME: process.env.HOME,
      DB_HOST: db.host,
      DB_PORT: String(db.port),
      DB_USER: db.user,
      DB_PASSWORD: db.password,
      DB_NAME: db.name,
    };
    const snapshot = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'rehearsal-')), 'before.json');
    const step = (title, script, args) => {
      console.log(`\n== ${title}\n$ node ${script} ${args.join(' ')}`);
      const r = spawnSync(process.execPath, [script, ...args], { cwd: BACKEND, env, encoding: 'utf8' });
      process.stdout.write(r.stdout.replace(/@ 127\.0\.0\.1:\d+/, '@ <throwaway mysql>'));
      process.stderr.write(r.stderr);
      if (r.status !== 0) throw new Error(`${title} failed (exit ${r.status})`);
    };

    step('Migration status BEFORE (Assignment 01 database, no migration history)', 'scripts/migrate.js', ['status']);
    step('Snapshot existing records', 'scripts/verify-migration.js', ['snapshot', snapshot]);
    step('Apply migrations', 'scripts/migrate.js', ['up']);
    step('Migration status AFTER', 'scripts/migrate.js', ['status']);
    step('Verify records against snapshot', 'scripts/verify-migration.js', ['verify', snapshot]);
    step('Re-run migrations (must be a no-op)', 'scripts/migrate.js', ['up']);
    console.log('\n== Rehearsal finished successfully');
  } finally {
    await mysql.stop();
  }
}

main().catch((err) => {
  console.error(`\n== Rehearsal FAILED: ${err.message}`);
  process.exit(1);
});
