const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const env = require('./env');

/** Shared connection pool used by every model / controller. */
const pool = mysql.createPool({
  host: env.db.host,
  port: env.db.port,
  user: env.db.user,
  password: env.db.password,
  database: env.db.name,
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

// Suppress unhandled error crash if an idle pooled connection is terminated by remote server
pool.on('connection', (connection) => {
  connection.on('error', (err) => {
    if (err.code === 'PROTOCOL_CONNECTION_LOST' || err.code === 'ECONNRESET') {
      // Handled silently; pool will re-establish connection on demand
    }
  });
});

// Resilient wrapper: auto-retry once on transient network/reset errors
const originalQuery = pool.query.bind(pool);
const originalExecute = pool.execute.bind(pool);
const originalGetConnection = pool.getConnection.bind(pool);

function isConnResetError(err) {
  return (
    err &&
    (err.code === 'ECONNRESET' ||
      err.code === 'PROTOCOL_CONNECTION_LOST' ||
      err.code === 'EPIPE' ||
      err.code === 'ETIMEDOUT')
  );
}

pool.query = async function (...args) {
  try {
    return await originalQuery(...args);
  } catch (err) {
    if (isConnResetError(err)) {
      console.warn(`[db] Connection interrupted (${err.code}), retrying query on fresh connection...`);
      return await originalQuery(...args);
    }
    throw err;
  }
};

pool.execute = async function (...args) {
  try {
    return await originalExecute(...args);
  } catch (err) {
    if (isConnResetError(err)) {
      console.warn(`[db] Connection interrupted (${err.code}), retrying execute on fresh connection...`);
      return await originalExecute(...args);
    }
    throw err;
  }
};

pool.getConnection = async function (...args) {
  try {
    return await originalGetConnection(...args);
  } catch (err) {
    if (isConnResetError(err)) {
      console.warn(`[db] Connection interrupted (${err.code}), retrying getConnection on fresh connection...`);
      return await originalGetConnection(...args);
    }
    throw err;
  }
};

/**
 * Executes Database/schema.sql (idempotent). Uses a dedicated connection
 * without a default database because the script creates it.
 */
async function initSchema() {
  const candidate1 = path.join(__dirname, '..', '..', 'Database', 'schema.sql');
  const candidate2 = path.join(__dirname, '..', '..', '..', 'Database', 'schema.sql');
  const schemaPath = fs.existsSync(candidate1) ? candidate1 : candidate2;
  const sql = fs.readFileSync(schemaPath, 'utf8');
  const connection = await mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    multipleStatements: true,
  });
  try {
    await connection.query(sql);
  } finally {
    await connection.end();
  }
}

module.exports = { pool, initSchema };
