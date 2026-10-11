const app = require('./src/app');
const env = require('./src/config/env');
const { initSchema, pool } = require('./src/config/db');

// ExpenseMate Server Entry Point
async function start() {
  try {
    if (env.autoInitDb) {
      console.log('[server] Initializing database schema from Database/schema.sql...');
      await initSchema();
      console.log('[server] Database schema initialized successfully.');
    }

    // Test pool connection
    const [result] = await pool.query('SELECT 1 + 1 AS solution');
    console.log('[server] Connected to MySQL database successfully.');

    app.listen(env.port, () => {
      console.log(`[server] ExpenseMate Backend running on http://localhost:${env.port}`);
      console.log(`[server] REST API endpoints available at http://localhost:${env.port}/api`);
    });
  } catch (error) {
    console.error('[server] Failed to start server:', error);
    process.exit(1);
  }
}

start();
