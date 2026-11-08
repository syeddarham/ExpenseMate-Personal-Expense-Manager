/**
 * Base class for the Repository layer: the only layer allowed to run SQL.
 * Every repository receives a `Database` (see src/database/database.js).
 */
class BaseRepository {
  /** @param {import('../database/database').Database} db */
  constructor(db) {
    this.db = db;
  }

  /** Returns a copy bound to another Database, e.g. the one of an open transaction. */
  withDb(db) {
    return new this.constructor(db);
  }
}

module.exports = { BaseRepository };
