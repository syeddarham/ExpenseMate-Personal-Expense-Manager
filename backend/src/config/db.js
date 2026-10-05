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
  decimalNumbers: true, // DECIMAL columns are returned as JS numbers
  timezone: 'Z',
  charset: 'utf8mb4',
});

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
