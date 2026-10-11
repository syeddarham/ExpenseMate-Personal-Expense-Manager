const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { parseMonth, addMonths, toSqlDate } = require('../utils/dates');

/**
 * One row per expense category for the requested month. A limit set in an
 * earlier month carries forward until it is overridden.
 */
async function budgetsForMonth(userId, monthStart) {
  const next = addMonths(monthStart, 1);
  const [rows] = await pool.query(
    `SELECT c.id, c.name, c.icon, c.color, c.is_expense, c.user_id,
            COALESCE((SELECT b.limit_amount FROM budgets b
                       WHERE b.user_id = ? AND b.category_id = c.id AND b.month_start <= ?
                       ORDER BY b.month_start DESC LIMIT 1), 0) AS limit_amount,
            COALESCE((SELECT SUM(t.amount) FROM transactions t
                       WHERE t.user_id = ? AND t.category_id = c.id AND t.type = 'expense'
                         AND t.transaction_date >= ? AND t.transaction_date < ?), 0) AS spent_amount
       FROM categories c
      WHERE c.is_expense = 1 AND c.user_id = ?
      ORDER BY c.id`,
    [userId, toSqlDate(monthStart), userId, monthStart, next, userId],
  );
  return rows.map((r) => ({
    id: String(r.id),
    title: r.name,
    limit_amount: Number(r.limit_amount),
    spent_amount: Number(r.spent_amount),
    month: monthStart.toISOString(),
    category: {
      id: String(r.id),
      name: r.name,
      icon: r.icon,
      color: r.color,
      is_expense: true,
      is_custom: r.user_id != null,
    },
  }));
}

/** GET /api/budgets?month=YYYY-MM */
const listBudgets = asyncHandler(async (req, res) => {
  const monthStart = parseMonth(req.query.month);
  res.json({ budgets: await budgetsForMonth(req.user.id, monthStart) });
});

/** PUT /api/budgets/:categoryId  { limit_amount, month? } */
const setBudget = asyncHandler(async (req, res) => {
  const v = new Validator();
  const categoryId = v.id(req.params.categoryId, 'categoryId');
  const limit = v.nonNegativeNumber(req.body.limit_amount, 'limit_amount');
  v.assert();

  const [cats] = await pool.query(
    'SELECT id FROM categories WHERE id = ? AND is_expense = 1 AND user_id = ?',
    [categoryId, req.user.id],
  );
  if (cats.length === 0) throw new HttpError(404, 'Expense category not found', 'NOT_FOUND');

  const monthStart = parseMonth(req.body.month);
  await pool.query(
    `INSERT INTO budgets (user_id, category_id, month_start, limit_amount) VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE limit_amount = VALUES(limit_amount)`,
    [req.user.id, categoryId, toSqlDate(monthStart), limit],
  );

  const budgets = await budgetsForMonth(req.user.id, monthStart);
  res.json({ budget: budgets.find((b) => b.category.id === String(categoryId)), budgets });
});

module.exports = { listBudgets, setBudget };
