const { BaseRepository } = require('./base.repository');

/**
 * Raw budget rows. Deciding which limit applies to a month (carry-forward)
 * is a business rule and lives in BudgetService, not in SQL.
 */
class BudgetRepository extends BaseRepository {
  /** Every limit the user set for months up to and including `monthDate` (YYYY-MM-DD). */
  async listLimitsUpTo(userId, monthDate) {
    const rows = await this.db.query(
      `SELECT category_id, DATE_FORMAT(month_start, '%Y-%m-%d') AS month_start, limit_amount
         FROM budgets
        WHERE user_id = ? AND month_start <= ?
        ORDER BY category_id, month_start`,
      [userId, monthDate],
    );
    return rows.map((r) => ({ categoryId: r.category_id, monthStart: r.month_start, limit: Number(r.limit_amount) }));
  }

  async upsert(userId, categoryId, monthDate, limit) {
    await this.db.query(
      `INSERT INTO budgets (user_id, category_id, month_start, limit_amount) VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE limit_amount = VALUES(limit_amount)`,
      [userId, categoryId, monthDate, limit],
    );
  }

  async scaleLimits(userId, rate) {
    await this.db.query('UPDATE budgets SET limit_amount = ROUND(limit_amount * ?, 2) WHERE user_id = ?', [rate, userId]);
  }
}

module.exports = { BudgetRepository };
