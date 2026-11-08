/**
 * Starts a throwaway MySQL server for a test file (no installation needed:
 * mysql-memory-server downloads the binary once and caches it in the OS temp
 * directory). Production runs MySQL 8.0.44; 8.0.31 is the closest release
 * that runs on the team's macOS 12 machines.
 */
const mysql = require('mysql2/promise');
const { createDB } = require('mysql-memory-server');

const MYSQL_VERSION = process.env.TEST_MYSQL_VERSION || '8.0.31';

async function startMysql() {
  const server = await createDB({ version: MYSQL_VERSION, logLevel: 'ERROR' });
  const base = { host: '127.0.0.1', port: server.port, user: server.username, password: '' };
  let counter = 0;

  return {
    base,
    /** Creates an empty database and returns its connection settings (env.db shape). */
    async createDatabase(prefix = 'test') {
      const name = `${prefix}_${process.pid}_${++counter}`;
      const conn = await mysql.createConnection(base);
      await conn.query(`CREATE DATABASE \`${name}\``);
      await conn.end();
      return { ...base, name };
    },
    /** Opens a multi-statement connection to one database. */
    connect(db) {
      return mysql.createConnection({ ...base, database: db.name, multipleStatements: true, decimalNumbers: true });
    },
    stop: () => server.stop(),
  };
}

module.exports = { startMysql, MYSQL_VERSION };
