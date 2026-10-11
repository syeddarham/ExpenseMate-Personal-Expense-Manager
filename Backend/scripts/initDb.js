const { initSchema } = require('../src/config/db');

async function main() {
  try {
    console.log('[initDb] Executing Database/schema.sql...');
    await initSchema();
    console.log('[initDb] Done! Database and tables are ready.');
    process.exit(0);
  } catch (err) {
    console.error('[initDb] Error initializing schema:', err);
    process.exit(1);
  }
}

main();
