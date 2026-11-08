#!/usr/bin/env node
/**
 * Database migration CLI.
 *   npm run migrate            apply pending migrations
 *   npm run migrate:status     list migrations and whether they are applied
 *   npm run migrate:down       roll back the latest migration
 */
const env = require('../src/config/env');
const { Migrator } = require('../src/database/migrator');

async function main() {
  const command = process.argv[2] || 'up';
  const migrator = new Migrator({ db: env.db });

  if (command === 'status') {
    const rows = await migrator.status();
    console.log(`Database: ${env.db.name} @ ${env.db.host}:${env.db.port}`);
    for (const m of rows) {
      const state = m.applied ? `applied ${new Date(m.appliedAt).toISOString()}` : 'PENDING';
      const drift = m.checksumMatches === false ? '  !! CHECKSUM MISMATCH' : '';
      console.log(`  ${m.version}_${m.name.padEnd(28)} ${state}${drift}`);
    }
  } else if (command === 'up') {
    const applied = await migrator.up();
    console.log(applied.length ? `Applied: ${applied.join(', ')}` : 'Nothing to apply.');
  } else if (command === 'down') {
    await migrator.down();
  } else {
    throw new Error(`Unknown command "${command}" (use up | down | status)`);
  }
}

main().catch((err) => {
  console.error('[migrate] FAILED:', err.message);
  process.exit(1);
});
