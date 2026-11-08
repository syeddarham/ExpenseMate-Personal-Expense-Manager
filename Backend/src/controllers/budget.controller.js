const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { budgetToJson } = require('../utils/serializers');
const { parseMonth } = require('../utils/dates');

/** HTTP layer for /api/budgets (Monthly Budget Summary). */
function createBudgetController({ budgetService }) {
  return {
    /** GET /api/budgets?month=YYYY-MM */
    list: asyncHandler(async (req, res) => {
      const summary = await budgetService.monthlySummary(req.user.id, parseMonth(req.query.month));
      res.json({ budgets: summary.map(budgetToJson) });
    }),

    /** PUT /api/budgets/:categoryId  { limit_amount, month? } */
    set: asyncHandler(async (req, res) => {
      const v = new Validator();
      const categoryId = v.id(req.params.categoryId, 'categoryId');
      const limit = v.nonNegativeNumber(req.body.limit_amount, 'limit_amount');
      v.assert();

      const { budget, summary } = await budgetService.setLimit(req.user.id, categoryId, limit, parseMonth(req.body.month));
      res.json({ budget: budgetToJson(budget), budgets: summary.map(budgetToJson) });
    }),
  };
}

module.exports = { createBudgetController };
