const { BaseRepository } = require('./base.repository');

/**
 * Columns returned for every transaction read. After migration 002 the
 * receipt lives in transaction_receipts and is joined back in as
 * `receipt_url`, so the API contract is unchanged.
 */
const TRANSACTION_SELECT = `
  SELECT t.id, t.title, t.amount, t.type, t.note, t.tags, r.content AS receipt_url, t.transaction_date,
         t.account_id, a.name AS account_name,
         t.category_id, c.name AS category_name, c.icon AS category_icon,
         c.color AS category_color, c.is_expense AS category_is_expense
    FROM transactions t
    JOIN accounts a   ON a.id = t.account_id
    JOIN categories c ON c.id = t.category_id
    LEFT JOIN transaction_receipts r ON r.transaction_id = t.id`;

const ORDER_NEWEST_FIRST = 'ORDER BY t.transaction_date DESC, t.id DESC';

class TransactionRepository extends BaseRepository {
  /**
   * @param {number} userId
   * @param {{ type?: string, categoryId?: number, accountId?: number, from?: Date, to?: Date,
   *           search?: string, limit: number, offset: number }} filter
   */
  async list(userId, filter) {
    const where = ['t.user_id = ?'];
    const params = [userId];
    if (filter.type) {
      where.push('t.type = ?');
      params.push(filter.type);
    }
    if (filter.categoryId) {
      where.push('t.category_id = ?');
      params.push(filter.categoryId);
    }
    if (filter.accountId) {
      where.push('t.account_id = ?');
      params.push(filter.accountId);
    }
    if (filter.from) {
      where.push('t.transaction_date >= ?');
      params.push(filter.from);
    }
    if (filter.to) {
      where.push('t.transaction_date < ?');
      params.push(filter.to);
    }
    if (filter.search) {
      where.push('(t.title LIKE ? OR t.note LIKE ?)');
      params.push(`%${filter.search}%`, `%${filter.search}%`);
    }
    return this.db.query(`${TRANSACTION_SELECT} WHERE ${where.join(' AND ')} ${ORDER_NEWEST_FIRST} LIMIT ? OFFSET ?`, [
      ...params,
      filter.limit,
      filter.offset,
    ]);
  }

  async listAll(userId) {
    return this.db.query(`${TRANSACTION_SELECT} WHERE t.user_id = ? ${ORDER_NEWEST_FIRST}`, [userId]);
  }

  async listRecent(userId, limit) {
    return this.db.query(`${TRANSACTION_SELECT} WHERE t.user_id = ? ${ORDER_NEWEST_FIRST} LIMIT ?`, [userId, limit]);
  }

  async findById(id, userId) {
    const rows = await this.db.query(`${TRANSACTION_SELECT} WHERE t.id = ? AND t.user_id = ?`, [id, userId]);
    return rows[0] || null;
  }

  /** @returns {Promise<number>} new transaction id */
  async create(userId, t) {
    const result = await this.db.query(
      `INSERT INTO transactions
         (user_id, account_id, category_id, title, amount, type, note, tags, transaction_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, t.accountId, t.categoryId, t.title, t.amount, t.type, t.note, t.tags, t.date],
    );
    return result.insertId;
  }

  async update(id, userId, t) {
    await this.db.query(
      `UPDATE transactions
          SET account_id = ?, category_id = ?, title = ?, amount = ?, type = ?,
              note = ?, tags = ?, transaction_date = ?
        WHERE id = ? AND user_id = ?`,
      [t.accountId, t.categoryId, t.title, t.amount, t.type, t.note, t.tags, t.date, id, userId],
    );
  }

  /** @returns {Promise<boolean>} true when a row was deleted */
  async delete(id, userId) {
    const result = await this.db.query('DELETE FROM transactions WHERE id = ? AND user_id = ?', [id, userId]);
    return result.affectedRows > 0;
  }

  async countByCategory(categoryId, userId) {
    const rows = await this.db.query('SELECT COUNT(*) AS c FROM transactions WHERE category_id = ? AND user_id = ?', [
      categoryId,
      userId,
    ]);
    return Number(rows[0].c);
  }

  /** Income and expense totals in [from, to); both bounds optional. */
  async sumByType(userId, { from = null, to = null } = {}) {
    const where = ['user_id = ?'];
    const params = [userId];
    if (from) {
      where.push('transaction_date >= ?');
      params.push(from);
    }
    if (to) {
      where.push('transaction_date < ?');
      params.push(to);
    }
    const rows = await this.db.query(
      `SELECT COALESCE(SUM(CASE WHEN type = 'income'  THEN amount END), 0) AS income,
              COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense
         FROM transactions WHERE ${where.join(' AND ')}`,
      params,
    );
    return { income: Number(rows[0].income), expense: Number(rows[0].expense) };
  }

  /** Expense total per category in [from, to), with category details. */
  async expenseTotalsByCategory(userId, from, to) {
    const rows = await this.db.query(
      `SELECT c.id, c.name, c.icon, c.color, c.user_id, SUM(t.amount) AS amount
         FROM transactions t
         JOIN categories c ON c.id = t.category_id
        WHERE t.user_id = ? AND t.type = 'expense' AND t.transaction_date >= ? AND t.transaction_date < ?
        GROUP BY c.id
        ORDER BY amount DESC`,
      [userId, from, to],
    );
    return rows.map((r) => ({ ...r, amount: Number(r.amount) }));
  }

  /** Bare amount/type/date rows in [from, to) for trend bucketing. */
  async listAmountsInRange(userId, from, to) {
    const rows = await this.db.query(
      'SELECT amount, type, transaction_date FROM transactions WHERE user_id = ? AND transaction_date >= ? AND transaction_date < ?',
      [userId, from, to],
    );
    return rows.map((r) => ({ amount: Number(r.amount), type: r.type, date: new Date(r.transaction_date) }));
  }

  async scaleAmounts(userId, rate) {
    await this.db.query('UPDATE transactions SET amount = ROUND(amount * ?, 2) WHERE user_id = ?', [rate, userId]);
  }
}

module.exports = { TransactionRepository };
