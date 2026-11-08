const test = require('node:test');
const assert = require('node:assert/strict');
const { BudgetService, effectiveLimits } = require('../../src/services/budget.service');
const { fakeRepo } = require('../helpers/fakes');

const FOOD = { id: 1, name: 'Food', icon: 'restaurant', color: '#F59E0B', is_expense: 1, user_id: 7 };
const RENT = { id: 2, name: 'Rent', icon: 'home', color: '#3B82F6', is_expense: 1, user_id: 7 };
const SALARY = { id: 3, name: 'Salary', icon: 'work', color: '#059669', is_expense: 0, user_id: 7 };

function makeService({ limits = [], spending = [], categories = [FOOD, RENT] } = {}) {
  const budgetRepository = fakeRepo({
    listLimitsUpTo: (_u, monthDate) => limits.filter((l) => l.monthStart <= monthDate),
    upsert: () => {},
  });
  const categoryRepository = fakeRepo({
    listExpenseCategories: () => categories,
    findOwned: (id) => [...categories, SALARY].find((c) => c.id === id) || null,
  });
  const transactionRepository = fakeRepo({ expenseTotalsByCategory: () => spending });
  return { service: new BudgetService({ budgetRepository, categoryRepository, transactionRepository }), budgetRepository };
}

test('effectiveLimits: the latest limit for each category wins (carry-forward rule)', () => {
  const limits = effectiveLimits([
    { categoryId: 1, monthStart: '2026-01-01', limit: 100 },
    { categoryId: 1, monthStart: '2026-03-01', limit: 250 },
    { categoryId: 2, monthStart: '2026-02-01', limit: 900 },
  ]);
  assert.equal(limits.get(1), 250);
  assert.equal(limits.get(2), 900);
  assert.equal(limits.size, 2);
});

test('monthlySummary: one entry per expense category with limit and spending', async () => {
  const { service } = makeService({
    limits: [{ categoryId: 1, monthStart: '2026-10-01', limit: 300 }],
    spending: [{ id: 1, amount: 120.5 }],
  });
  const summary = await service.monthlySummary(7, new Date(2026, 10, 1));
  assert.deepEqual(
    summary.map((b) => [b.category.name, b.limit, b.spent]),
    [
      ['Food', 300, 120.5],
      ['Rent', 0, 0],
    ],
  );
});

test('monthlySummary: a limit set in an earlier month still applies later', async () => {
  const { service } = makeService({ limits: [{ categoryId: 2, monthStart: '2026-01-01', limit: 1000 }] });
  const summary = await service.monthlySummary(7, new Date(2026, 5, 1));
  assert.equal(summary.find((b) => b.category.id === 2).limit, 1000);
});

test('totalBudgetForMonth: counts each category once even after the limit was changed (defect D2)', async () => {
  // Assignment 01 summed every historical row: 100 + 250 + 900 = 1250.
  const { service } = makeService({
    limits: [
      { categoryId: 1, monthStart: '2026-01-01', limit: 100 },
      { categoryId: 1, monthStart: '2026-03-01', limit: 250 },
      { categoryId: 2, monthStart: '2026-02-01', limit: 900 },
    ],
  });
  assert.equal(await service.totalBudgetForMonth(7, new Date(2026, 3, 1)), 1150);
});

test('setLimit: rejects income categories and unknown ids', async () => {
  const { service, budgetRepository } = makeService();
  await assert.rejects(service.setLimit(7, SALARY.id, 50, new Date(2026, 0, 1)), { status: 404 });
  await assert.rejects(service.setLimit(7, 999, 50, new Date(2026, 0, 1)), { status: 404 });
  assert.equal(budgetRepository.called('upsert').length, 0);
});

test('setLimit: stores the limit for the month and returns the updated entry', async () => {
  const limits = [];
  const { service, budgetRepository } = makeService({ limits });
  budgetRepository.upsert = async (_u, categoryId, monthStart, limit) => limits.push({ categoryId, monthStart, limit });
  const { budget, summary } = await service.setLimit(7, FOOD.id, 75, new Date(2026, 4, 1));
  assert.deepEqual(limits, [{ categoryId: 1, monthStart: '2026-05-01', limit: 75 }]);
  assert.equal(budget.limit, 75);
  assert.equal(summary.length, 2);
});
