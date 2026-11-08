const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

const DEFAULT_DIR = path.join(__dirname, '..', '..', 'Database', 'migrations');
const FILE_RE = /^(\d{3})_([a-z0-9_]+)\.(up|down)\.sql$/;
const LOCK_NAME = 'expensemate_migrations';

/**
 * Versioned schema migrations (replaces the single Assignment 01 schema.sql).
 *
 * Migrations live in Database/migrations as NNN_name.up.sql (+ optional
 * NNN_name.down.sql). Applied versions are recorded in `schema_migrations`
 * with a SHA-256 checksum so an edited, already-applied migration is
 * detected instead of silently drifting.
 */
class Migrator {
  /**
   * @param {object} options
   * @param {object} options.db  { host, port, user, password, name }
   * @param {string} [options.dir] migrations directory
   * @param {(msg: string) => void} [options.log]
   */
  constructor({ db, dir = DEFAULT_DIR, log = console.log }) {
    if (!db || !db.name) throw new Error('Migrator requires db.name');
    this.dbConfig = db;
    this.dir = dir;
    this.log = log;
  }

  /** Reads and pairs the migration files on disk, sorted by version. */
  loadMigrations() {
    const byVersion = new Map();
    for (const file of fs.readdirSync(this.dir).sort()) {
      const match = FILE_RE.exec(file);
      if (!match) continue;
      const [, version, name, direction] = match;
      const entry = byVersion.get(version) || { version, name };
      if (entry.name !== name) throw new Error(`Migration ${version} has mismatched names: ${entry.name} / ${name}`);
      const sql = fs.readFileSync(path.join(this.dir, file), 'utf8');
      entry[direction] = sql;
      if (direction === 'up') entry.checksum = checksum(sql);
      byVersion.set(version, entry);
    }
    const migrations = [...byVersion.values()];
    for (const m of migrations) {
      if (!m.up) throw new Error(`Migration ${m.version}_${m.name} has no .up.sql file`);
    }
    return migrations;
  }

  /** Lists every migration with its applied state. */
  async status() {
    return this.withConnection(async (conn) => {
      const applied = await this.appliedVersions(conn);
      return this.loadMigrations().map((m) => ({
        version: m.version,
        name: m.name,
        applied: applied.has(m.version),
        appliedAt: applied.get(m.version)?.applied_at || null,
        checksumMatches: applied.has(m.version) ? applied.get(m.version).checksum === m.checksum : null,
      }));
    });
  }

  /** Applies every pending migration in order. Returns the versions applied. */
  async up() {
    return this.withConnection(async (conn) => {
      const migrations = this.loadMigrations();
      const applied = await this.appliedVersions(conn);

      for (const m of migrations) {
        const row = applied.get(m.version);
        if (row && row.checksum !== m.checksum) {
          throw new Error(
            `Migration ${m.version}_${m.name} was modified after it was applied (checksum mismatch). ` +
              'Create a new migration instead of editing an applied one.',
          );
        }
      }

      const pending = migrations.filter((m) => !applied.has(m.version));
      if (pending.length === 0) {
        this.log('[migrate] Database is up to date.');
        return [];
      }

      const done = [];
      for (const m of pending) {
        const started = Date.now();
        this.log(`[migrate] Applying ${m.version}_${m.name} ...`);
        await conn.query(m.up);
        await conn.query('INSERT INTO schema_migrations (version, name, checksum) VALUES (?, ?, ?)', [
          m.version,
          m.name,
          m.checksum,
        ]);
        this.log(`[migrate] Applied ${m.version}_${m.name} in ${Date.now() - started} ms`);
        done.push(m.version);
      }
      return done;
    });
  }

  /** Rolls back the most recently applied migration. */
  async down() {
    return this.withConnection(async (conn) => {
      const [rows] = await conn.query('SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1');
      if (rows.length === 0) {
        this.log('[migrate] Nothing to roll back.');
        return null;
      }
      const m = this.loadMigrations().find((x) => x.version === rows[0].version);
      if (!m) throw new Error(`Applied migration ${rows[0].version} is missing from ${this.dir}`);
      if (!m.down) throw new Error(`Migration ${m.version}_${m.name} is irreversible (no .down.sql file)`);

      this.log(`[migrate] Rolling back ${m.version}_${m.name} ...`);
      await conn.query(m.down);
      await conn.query('DELETE FROM schema_migrations WHERE version = ?', [m.version]);
      this.log(`[migrate] Rolled back ${m.version}_${m.name}`);
      return m.version;
    });
  }

  // -------------------------------------------------------------------------

  async appliedVersions(conn) {
    const [rows] = await conn.query('SELECT version, checksum, applied_at FROM schema_migrations');
    return new Map(rows.map((r) => [r.version, r]));
  }

  /**
   * Opens a dedicated multi-statement connection, creates the database and
   * bookkeeping table if needed, and holds a named lock so two server
   * instances never migrate at the same time.
   */
  async withConnection(work) {
    const { host, port, user, password, name } = this.dbConfig;
    const conn = await mysql.createConnection({ host, port, user, password, multipleStatements: true });
    try {
      await conn.query(`CREATE DATABASE IF NOT EXISTS ${mysql.escapeId(name)} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
      await conn.query(`USE ${mysql.escapeId(name)}`);
      const [[lock]] = await conn.query('SELECT GET_LOCK(?, 60) AS ok', [LOCK_NAME]);
      if (lock.ok !== 1) throw new Error('Timed out waiting for the migration lock');
      try {
        await conn.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
          version     CHAR(3)      NOT NULL,
          name        VARCHAR(100) NOT NULL,
          checksum    CHAR(64)     NOT NULL,
          applied_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (version)
        ) ENGINE=InnoDB`);
        return await work(conn);
      } finally {
        await conn.query('SELECT RELEASE_LOCK(?)', [LOCK_NAME]);
      }
    } finally {
      await conn.end();
    }
  }
}

function checksum(sql) {
  // Normalise line endings so a Windows checkout does not look "modified".
  return crypto.createHash('sha256').update(sql.replace(/\r\n/g, '\n')).digest('hex');
}

module.exports = { Migrator, checksum };
