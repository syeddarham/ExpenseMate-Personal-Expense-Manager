const test = require('node:test');
const assert = require('node:assert/strict');
const { TransactionService } = require('../../src/services/transaction.service');
const { fakeDb, fakeRepo } = require('../helpers/fakes');

const USER = 7;
const CATEGORIES = [
  { id: 10, name: 'Groceries', is_expense: 1 },
  { id: 11, name: 'Salary / Income', is_expense: 0 },
];

function makeService({ accounts = [{ id: 20, name: 'Cash' }, { id: 21, name: 'Bank Account' }] } = {}) {
  const rows = new Map();
  const transactionRepository = fakeRepo({
    create: (_u, data) => {
      const id = rows.size + 100;
      rows.set(id, { id, ...data });
      return id;
    },
    update: (id, _u, data) => rows.set(id, { id, ...data }),
    findById: (id) => rows.get(id) || null,
    delete: (id) => rows.delete(id),
  });
  const receiptRepository = fakeRepo({ upsert: () => {}, delete: () => {} });
  const categoryRepository = fakeRepo({
    findOwned: (id) => CATEGORIES.find((c) => c.id === id) || null,
    findIdByNameLike: (_u, name, preferExpense) => {
      const matches = CATEGORIES.filter((c) => c.name.toLowerCase().includes(name.toLowerCase()));
      matches.sort((a, b) => Number(b.is_expense === (preferExpense ? 1 : 0)) - Number(a.is_expense === (preferExpense ? 1 : 0)));
      return matches[0]?.id || null;
    },
    findFirstIdOfKind: (_u, isExpense) => CATEGORIES.find((c) => !!c.is_expense === isExpense)?.id || null,
  });
  const accountRepository = fakeRepo({
    findIdOwnedBy: (id) => accounts.find((a) => a.id === id)?.id || null,
    findIdByName: (_u, name) => accounts.find((a) => a.name.toLowerCase().includes(name.toLowerCase()))?.id || null,
    findFirstId: () => accounts[0]?.id || null,
    create: () => 99,
  });
  const db = fakeDb();
  const service = new TransactionService({ db, transactionRepository, receiptRepository, categoryRepository, accountRepository });
  return { service, db, rows, receiptRepository, accountRepository };
}

const base = { title: 'Lunch', amount: 12.5, type: 'expense', date: new Date('2026-11-01T12:00:00Z') };

test('resolveCategoryId: numeric id owned by the user is used as-is', async () => {
  const { service } = makeService();
  assert.equal(await service.resolveCategoryId(USER, '10', 'expense'), 10);
});

test('resolveCategoryId: a name (or part of one) is matched', async () => {
  const { service } = makeService();
  assert.equal(await service.resolveCategoryId(USER, 'grocer', 'expense'), 10);
});

test('resolveCategoryId: unknown values fall back to the first category of the right kind', async () => {
  const { service } = makeService();
  assert.equal(await service.resolveCategoryId(USER, 'does-not-exist', 'income'), 11);
  assert.equal(await service.resolveCategoryId(USER, undefined, 'expense'), 10);
});

test('resolveAccountId: id, then name, then first account, then a new "Cash" account', async () => {
  const { service } = makeService();
  assert.equal(await service.resolveAccountId(USER, 21), 21);
  assert.equal(await service.resolveAccountId(USER, 'bank'), 21);
  assert.equal(await service.resolveAccountId(USER, null), 20);

  const empty = makeService({ accounts: [] });
  assert.equal(await empty.service.resolveAccountId(USER, null), 99);
  assert.deepEqual(empty.accountRepository.called('create')[0].args[1], { name: 'Cash', type: 'cash' });
});

test('create: stores the row and its receipt inside one database transaction', async () => {
  const { service, db, receiptRepository } = makeService();
  const created = await service.create(USER, { ...base, category: 'Groceries', account: 'Cash', receiptUrl: 'data:image/png;base64,AAA' });
  assert.equal(created.categoryId, 10);
  assert.equal(created.accountId, 20);
  assert.equal(db.transactions, 1);
  assert.deepEqual(receiptRepository.called('upsert')[0].args, [created.id, 'data:image/png;base64,AAA']);
});

test('create: no receipt row is written when none is attached', async () => {
  const { service, receiptRepository } = makeService();
  await service.create(USER, base);
  assert.equal(receiptRepository.called('upsert').length, 0);
});

test('update: omitting the receipt removes the stored one (PUT replaces the whole record)', async () => {
  const { service, receiptRepository } = makeService();
  const created = await service.create(USER, { ...base, receiptUrl: 'https://example.com/r.jpg' });
  await service.update(created.id, USER, { ...base, title: 'Dinner' });
  assert.deepEqual(receiptRepository.called('delete')[0].args, [created.id]);
});

test('get/update/delete: unknown ids give 404', async () => {
  const { service } = makeService();
  await assert.rejects(service.get(1, USER), { status: 404 });
  await assert.rejects(service.update(1, USER, base), { status: 404 });
  await assert.rejects(service.delete(1, USER), { status: 404 });
});
