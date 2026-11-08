const { NotFoundError } = require('../utils/http');
const { addMonths, toSqlDate } = require('../utils/dates');

/**
 * Business rule: a limit set for a month keeps applying to later months
 * until a newer limit overrides it. Rows must be ordered by month ascending.
 *
 * @param {{ categoryId: number, monthStart: string, limit: number }[]} limitRows
 * @returns {Map<number, number>} categoryId -> limit in effect
 */
function effectiveLimits(limitRows) {
  const limits = new Map();
  for (const row of limitRows) limits.set(Number(row.categoryId), row.limit);
  return limits;
}

/** Monthly budgets: one entry per expense category with its limit and spending. */
class BudgetService {
  constructor({ budgetRepository, categoryRepository, transactionRepository }) {
    this.budgets = budgetRepository;
    this.categories = categoryRepository;
    this.transactions = transactionRepository;
  }

  /**
   * @param {number} userId
   * @param {Date} monthStart first day of the month (local time)
   * @returns {Promise<{ category: object, limit: number, spent: number, monthStart: Date }[]>}
   */
  async monthlySummary(userId, monthStart) {
    const [categories, limitRows, spending] = await Promise.all([
      this.categories.listExpenseCategories(userId),
      this.budgets.listLimitsUpTo(userId, toSqlDate(monthStart)),
      this.transactions.expenseTotalsByCategory(userId, monthStart, addMonths(monthStart, 1)),
    ]);
    const limits = effectiveLimits(limitRows);
    const spentByCategory = new Map(spending.map((s) => [Number(s.id), s.amount]));

    return categories.map((category) => ({
      category,
      limit: limits.get(Number(category.id)) || 0,
      spent: spentByCategory.get(Number(category.id)) || 0,
      monthStart,
    }));
  }

  /** Sum of the limits in effect this month (what the dashboard shows as "budget"). */
  async totalBudgetForMonth(userId, monthStart) {
    const summary = await this.monthlySummary(userId, monthStart);
    return Math.round(summary.reduce((sum, b) => sum + b.limit, 0) * 100) / 100;
  }

  /** Sets the limit for one expense category from `monthStart` onwards. */
  async setLimit(userId, categoryId, limit, monthStart) {
    const category = await this.categories.findOwned(categoryId, userId);
    if (!category || !category.is_expense) throw new NotFoundError('Expense category not found');

    await this.budgets.upsert(userId, categoryId, toSqlDate(monthStart), limit);
    const summary = await this.monthlySummary(userId, monthStart);
    return { budget: summary.find((b) => Number(b.category.id) === Number(categoryId)), summary };
  }
}

module.exports = { BudgetService, effectiveLimits };
