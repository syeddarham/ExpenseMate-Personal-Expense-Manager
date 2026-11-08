const mysql = require('mysql2/promise');

const TRANSIENT_CODES = new Set(['ECONNRESET', 'PROTOCOL_CONNECTION_LOST', 'EPIPE', 'ETIMEDOUT']);

/**
 * Creates the MySQL connection pool (the "Database" layer).
 * Transient network errors on an idle pooled connection are retried once.
 *
 * @param {{ host: string, port: number, user: string, password: string, name: string }} config
 */
function createPool(config) {
  const pool = mysql.createPool({
    host: config.host,
    port: config.port,
    user: config.user,
    password: config.password,
    database: config.name,
    waitForConnections: true,
    connectionLimit: 10,
    maxIdle: 10,
    idleTimeout: 30000,
    enableKeepAlive: true,
    keepAliveInitialDelay: 5000,
    decimalNumbers: true, // DECIMAL columns are returned as JS numbers
    timezone: 'Z',
    charset: 'utf8mb4',
  });

  // An idle connection dropped by the server must not crash the process;
  // the pool re-establishes connections on demand.
  pool.on('connection', (connection) => {
    connection.on('error', () => {});
  });

  for (const method of ['query', 'execute', 'getConnection']) {
    const original = pool[method].bind(pool);
    pool[method] = async (...args) => {
      try {
        return await original(...args);
      } catch (err) {
        if (!TRANSIENT_CODES.has(err && err.code)) throw err;
        console.warn(`[db] Connection interrupted (${err.code}), retrying ${method} once...`);
        return original(...args);
      }
    };
  }

  return pool;
}

module.exports = { createPool };
