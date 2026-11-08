const env = require('./src/config/env');
const { buildContainer } = require('./src/container');
const { createApp } = require('./src/app');
const { Migrator } = require('./src/database/migrator');

// ExpenseMate Server Entry Point
async function start() {
  try {
    if (env.autoInitDb) {
      console.log('[server] Applying pending database migrations...');
      await new Migrator({ db: env.db }).up();
    }

    const container = buildContainer({ env });
    await container.db.query('SELECT 1');
    console.log('[server] Connected to MySQL database successfully.');

    const app = createApp(container);
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
