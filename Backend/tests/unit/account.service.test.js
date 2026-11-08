const test = require('node:test');
const assert = require('node:assert/strict');
const { AccountService, accountBalance, DEFAULT_ACCOUNTS } = require('../../src/services/account.service');
const { fakeRepo } = require('../helpers/fakes');

test('accountBalance: opening + income - expense, rounded to cents', () => {
  assert.equal(accountBalance({ opening_balance: 100, income_total: 0.1, expense_total: 0.2 }), 99.9);
  assert.equal(accountBalance({ opening_balance: 0 }), 0);
});

test('ensureDefaultAccounts: creates the five starter accounts only when the user has none', async () => {
  let count = 0;
  const repo = fakeRepo({ countForUser: () => count, create: () => ++count });
  const service = new AccountService({ accountRepository: repo });

  await service.ensureDefaultAccounts(7);
  assert.equal(repo.called('create').length, DEFAULT_ACCOUNTS.length);

  await service.ensureDefaultAccounts(7);
  assert.equal(repo.called('create').length, DEFAULT_ACCOUNTS.length, 'no duplicates on second login');
});

test('update/delete: accounts of other users are reported as not found', async () => {
  const repo = fakeRepo({ findWithTotals: () => null, delete: () => false, update: () => {} });
  const service = new AccountService({ accountRepository: repo });
  await assert.rejects(service.update(1, 7, { name: 'x' }), { status: 404 });
  await assert.rejects(service.delete(1, 7), { status: 404 });
  assert.equal(repo.called('update').length, 0);
});
