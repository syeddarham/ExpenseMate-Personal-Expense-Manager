const test = require('node:test');
const assert = require('node:assert/strict');
const { AnalyticsService, categoryBreakdown, bucketTrend } = require('../../src/services/analytics.service');
const { fakeRepo } = require('../helpers/fakes');

test('categoryBreakdown: percentages of total spending, one decimal place', () => {
  const rows = [
    { id: 1, name: 'Food', amount: 50 },
    { id: 2, name: 'Rent', amount: 100 },
  ];
  assert.deepEqual(
    categoryBreakdown(rows, 150).map((c) => c.percentage),
    [33.3, 66.7],
  );
  assert.deepEqual(
    categoryBreakdown(rows, 0).map((c) => c.percentage),
    [0, 0],
  );
});

test('bucketTrend: each transaction lands in exactly one [start, end) bucket', () => {
  const buckets = [
    { label: 'W1', start: new Date(2026, 0, 1), end: new Date(2026, 0, 8) },
    { label: 'W2', start: new Date(2026, 0, 8), end: new Date(2026, 0, 15) },
  ];
  const txs = [
    { type: 'expense', amount: 10, date: new Date(2026, 0, 1) },
    { type: 'income', amount: 500, date: new Date(2026, 0, 7, 23, 59) },
    { type: 'expense', amount: 5, date: new Date(2026, 0, 8) }, // boundary -> W2
    { type: 'expense', amount: 99, date: new Date(2026, 0, 20) }, // outside
  ];
  assert.deepEqual(bucketTrend(txs, buckets), [
    { label: 'W1', expense: 10, income: 500 },
    { label: 'W2', expense: 5, income: 0 },
  ]);
});

test('overview: balance = opening balances + all-time income - all-time expense', async () => {
  const service = new AnalyticsService({
    accountRepository: fakeRepo({ sumOpeningBalances: () => 1000 }),
    transactionRepository: fakeRepo({
      sumByType: (_u, range) => (range ? { income: 200, expense: 80 } : { income: 3000.1, expense: 1200.2 }),
      listRecent: () => [],
    }),
    budgetService: { totalBudgetForMonth: async () => 450 },
  });
  const o = await service.overview(7, new Date(2026, 10, 15));
  assert.equal(o.totalBalance, 2799.9);
  assert.equal(o.totalIncome, 200);
  assert.equal(o.totalExpense, 80);
  assert.equal(o.totalBudget, 450);
});
