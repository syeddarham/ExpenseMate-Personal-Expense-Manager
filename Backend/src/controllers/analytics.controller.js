const { pool } = require('../config/db');
const { asyncHandler } = require('../utils/http');
const { periodRange, parseMonth, startOfMonth, addMonths, toSqlDate } = require('../utils/dates');
const { TRANSACTION_SELECT, transactionToJson } = require('../utils/serializers');

/**
 * GET /api/overview
 * Dashboard summary: balance, this month's flow, recent transactions.
 */
const getOverview = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const monthStart = startOfMonth(new Date());
  const monthEnd = addMonths(monthStart, 1);

  // Total balance across all accounts
  const [balanceRows] = await pool.query(
    `SELECT COALESCE(SUM(a.opening_balance), 0) +
            COALESCE((SELECT SUM(CASE type WHEN 'income' THEN amount WHEN 'expense' THEN -amount END)
                        FROM transactions WHERE user_id = ?), 0) AS total_balance
       FROM accounts a
      WHERE a.user_id = ?`,
    [userId, userId]
  );

  // Month income & expense
  const [monthFlow] = await pool.query(
    `SELECT
       COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
       COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
     FROM transactions
     WHERE user_id = ? AND transaction_date >= ? AND transaction_date < ?`,
    [userId, monthStart, monthEnd]
  );

  // Recent transactions
  const [recentRows] = await pool.query(
    `${TRANSACTION_SELECT} WHERE t.user_id = ? ORDER BY t.transaction_date DESC, t.id DESC LIMIT 10`,
    [userId]
  );

  // Budget summary for current month
  const [budgetRows] = await pool.query(
    `SELECT
       COALESCE(SUM(limit_amount), 0) AS total_budget
     FROM budgets
     WHERE user_id = ? AND month_start <= ?`,
    [userId, toSqlDate(monthStart)]
  );

  res.json({
    total_balance: Number(balanceRows[0]?.total_balance || 0),
    total_income: Number(monthFlow[0]?.total_income || 0),
    total_expense: Number(monthFlow[0]?.total_expense || 0),
    total_budget: Number(budgetRows[0]?.total_budget || 0),
    recent_transactions: recentRows.map(transactionToJson),
  });
});

/**
 * GET /api/analytics?period=day|week|month|year
 */
const getAnalytics = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const period = req.query.period || 'month';
  const { start, end, buckets } = periodRange(period);

  // Total income & expense in period
  const [flow] = await pool.query(
    `SELECT
       COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
       COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
     FROM transactions
     WHERE user_id = ? AND transaction_date >= ? AND transaction_date < ?`,
    [userId, start, end]
  );

  const totalExpense = Number(flow[0]?.total_expense || 0);
  const totalIncome = Number(flow[0]?.total_income || 0);

  // Category breakdown
  const [catRows] = await pool.query(
    `SELECT c.id, c.name, c.icon, c.color, c.is_expense, c.user_id,
            SUM(t.amount) AS amount
       FROM transactions t
       JOIN categories c ON c.id = t.category_id
      WHERE t.user_id = ? AND t.type = 'expense'
        AND t.transaction_date >= ? AND t.transaction_date < ?
      GROUP BY c.id
      ORDER BY amount DESC`,
    [userId, start, end]
  );

  const categorySpending = catRows.map((row) => {
    const amount = Number(row.amount);
    const percentage = totalExpense > 0 ? Number(((amount / totalExpense) * 100).toFixed(1)) : 0;
    return {
      category: {
        id: String(row.id),
        name: row.name,
        icon: row.icon,
        color: row.color,
        is_expense: true,
        is_custom: row.user_id != null,
      },
      amount,
      percentage,
    };
  });

  // Trend data bucketed
  const [txRows] = await pool.query(
    `SELECT amount, type, transaction_date
       FROM transactions
      WHERE user_id = ? AND transaction_date >= ? AND transaction_date < ?`,
    [userId, start, end]
  );

  const trend = buckets.map((bucket) => {
    const bStart = bucket.start.getTime();
    const bEnd = bucket.end.getTime();

    let expense = 0;
    let income = 0;

    for (const tx of txRows) {
      const txTime = new Date(tx.transaction_date).getTime();
      if (txTime >= bStart && txTime < bEnd) {
        if (tx.type === 'expense') expense += Number(tx.amount);
        else if (tx.type === 'income') income += Number(tx.amount);
      }
    }

    return {
      label: bucket.label,
      expense,
      income,
    };
  });

  res.json({
    period,
    total_income: totalIncome,
    total_expense: totalExpense,
    category_spending: categorySpending,
    trend,
  });
});

module.exports = { getOverview, getAnalytics };
