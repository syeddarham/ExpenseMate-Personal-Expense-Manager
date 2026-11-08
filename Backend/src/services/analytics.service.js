const { periodRange, startOfMonth, addMonths } = require('../utils/dates');

const RECENT_TRANSACTION_COUNT = 10;

/** Percentage share of each category in total spending (1 decimal place). */
function categoryBreakdown(rows, totalExpense) {
  return rows.map((row) => ({
    category: row,
    amount: row.amount,
    percentage: totalExpense > 0 ? Number(((row.amount / totalExpense) * 100).toFixed(1)) : 0,
  }));
}

/** Sums income and expense into each [start, end) bucket. */
function bucketTrend(transactions, buckets) {
  return buckets.map((bucket) => {
    const start = bucket.start.getTime();
    const end = bucket.end.getTime();
    let income = 0;
    let expense = 0;
    for (const tx of transactions) {
      const time = tx.date.getTime();
      if (time < start || time >= end) continue;
      if (tx.type === 'income') income += tx.amount;
      else if (tx.type === 'expense') expense += tx.amount;
    }
    return { label: bucket.label, expense, income };
  });
}

/** Dashboard overview and the analytics screen. */
class AnalyticsService {
  constructor({ accountRepository, transactionRepository, budgetService }) {
    this.accounts = accountRepository;
    this.transactions = transactionRepository;
    this.budgets = budgetService;
  }

  async overview(userId, now = new Date()) {
    const monthStart = startOfMonth(now);
    const [openingTotal, allTime, month, recent, totalBudget] = await Promise.all([
      this.accounts.sumOpeningBalances(userId),
      this.transactions.sumByType(userId),
      this.transactions.sumByType(userId, { from: monthStart, to: addMonths(monthStart, 1) }),
      this.transactions.listRecent(userId, RECENT_TRANSACTION_COUNT),
      this.budgets.totalBudgetForMonth(userId, monthStart),
    ]);
    return {
      totalBalance: round2(openingTotal + allTime.income - allTime.expense),
      totalIncome: month.income,
      totalExpense: month.expense,
      totalBudget,
      recentTransactions: recent,
    };
  }

  /** @param {string} period day | week | month | year (anything else behaves like month) */
  async analytics(userId, period, now = new Date()) {
    const { start, end, buckets } = periodRange(period, now);
    const [flow, byCategory, amounts] = await Promise.all([
      this.transactions.sumByType(userId, { from: start, to: end }),
      this.transactions.expenseTotalsByCategory(userId, start, end),
      this.transactions.listAmountsInRange(userId, start, end),
    ]);
    return {
      period,
      totalIncome: flow.income,
      totalExpense: flow.expense,
      categorySpending: categoryBreakdown(byCategory, flow.expense),
      trend: bucketTrend(amounts, buckets),
    };
  }
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

module.exports = { AnalyticsService, categoryBreakdown, bucketTrend };
