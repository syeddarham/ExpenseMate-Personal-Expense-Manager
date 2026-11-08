/**
 * Thin wrapper over a mysql2 pool (or a single connection inside a
 * transaction). Repositories receive one of these, never the raw pool, so
 * a service can run several repositories inside one database transaction:
 *
 *   await db.transaction(async (tx) => {
 *     const userId = await users.withDb(tx).create(...);
 *     await accounts.withDb(tx).create(userId, ...);
 *   });
 */
class Database {
  /** @param {import('mysql2/promise').Pool | import('mysql2/promise').PoolConnection} executor */
  constructor(executor, { inTransaction = false } = {}) {
    this.executor = executor;
    this.inTransaction = inTransaction;
  }

  /** Runs a parameterised statement and returns rows (SELECT) or the result header (writes). */
  async query(sql, params = []) {
    const [result] = await this.executor.query(sql, params);
    return result;
  }

  /** Runs `work(txDb)` in a transaction; commits on success, rolls back on error. */
  async transaction(work) {
    if (this.inTransaction) return work(this); // already inside one: join it

    const conn = await this.executor.getConnection();
    try {
      await conn.beginTransaction();
      const result = await work(new Database(conn, { inTransaction: true }));
      await conn.commit();
      return result;
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }
}

module.exports = { Database };
