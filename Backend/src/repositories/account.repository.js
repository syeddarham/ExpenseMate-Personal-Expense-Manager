const { BaseRepository } = require('./base.repository');

/**
 * Accounts plus their raw income/expense totals. The balance itself
 * (opening + income - expense) is a business rule computed in AccountService.
 */
const ACCOUNT_WITH_TOTALS = `
  SELECT a.id, a.user_id, a.name, a.type, a.opening_balance,
         COALESCE(SUM(CASE WHEN t.type = 'income'  THEN t.amount END), 0) AS income_total,
         COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount END), 0) AS expense_total
    FROM accounts a
    LEFT JOIN transactions t ON t.account_id = a.id`;

const UPDATABLE_COLUMNS = new Set(['name', 'type', 'opening_balance']);

class AccountRepository extends BaseRepository {
  async listWithTotals(userId) {
    return this.db.query(`${ACCOUNT_WITH_TOTALS} WHERE a.user_id = ? GROUP BY a.id ORDER BY a.id`, [userId]);
  }

  async findWithTotals(id, userId) {
    const rows = await this.db.query(`${ACCOUNT_WITH_TOTALS} WHERE a.id = ? AND a.user_id = ? GROUP BY a.id`, [id, userId]);
    return rows[0] || null;
  }

  async findIdOwnedBy(id, userId) {
    const rows = await this.db.query('SELECT id FROM accounts WHERE id = ? AND user_id = ?', [id, userId]);
    return rows.length > 0 ? rows[0].id : null;
  }

  /** Exact (case-insensitive) name match first, then substring match. */
  async findIdByName(userId, name) {
    const needle = name.trim().toLowerCase();
    const rows = await this.db.query(
      `SELECT id FROM accounts
        WHERE user_id = ? AND (LOWER(name) = ? OR LOWER(name) LIKE ?)
        ORDER BY LOWER(name) = ? DESC, id ASC
        LIMIT 1`,
      [userId, needle, `%${needle}%`, needle],
    );
    return rows.length > 0 ? rows[0].id : null;
  }

  async findFirstId(userId) {
    const rows = await this.db.query('SELECT id FROM accounts WHERE user_id = ? ORDER BY id ASC LIMIT 1', [userId]);
    return rows.length > 0 ? rows[0].id : null;
  }

  async countForUser(userId) {
    const rows = await this.db.query('SELECT COUNT(*) AS c FROM accounts WHERE user_id = ?', [userId]);
    return Number(rows[0].c);
  }

  async sumOpeningBalances(userId) {
    const rows = await this.db.query('SELECT COALESCE(SUM(opening_balance), 0) AS total FROM accounts WHERE user_id = ?', [userId]);
    return Number(rows[0].total);
  }

  /** @returns {Promise<number>} new account id */
  async create(userId, { name, type, openingBalance = 0 }) {
    const result = await this.db.query('INSERT INTO accounts (user_id, name, type, opening_balance) VALUES (?, ?, ?, ?)', [
      userId,
      name,
      type,
      openingBalance,
    ]);
    return result.insertId;
  }

  /** @param {Record<string, unknown>} changes column -> value (whitelisted) */
  async update(id, userId, changes) {
    const columns = Object.keys(changes);
    if (columns.length === 0) return;
    for (const column of columns) {
      if (!UPDATABLE_COLUMNS.has(column)) throw new Error(`Column ${column} cannot be updated`);
    }
    const assignments = columns.map((c) => `${c} = ?`).join(', ');
    await this.db.query(`UPDATE accounts SET ${assignments} WHERE id = ? AND user_id = ?`, [
      ...columns.map((c) => changes[c]),
      id,
      userId,
    ]);
  }

  /** @returns {Promise<boolean>} true when a row was deleted */
  async delete(id, userId) {
    const result = await this.db.query('DELETE FROM accounts WHERE id = ? AND user_id = ?', [id, userId]);
    return result.affectedRows > 0;
  }

  async scaleOpeningBalances(userId, rate) {
    await this.db.query('UPDATE accounts SET opening_balance = ROUND(opening_balance * ?, 2) WHERE user_id = ?', [rate, userId]);
  }
}

module.exports = { AccountRepository };
