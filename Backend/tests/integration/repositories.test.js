/**
 * Repository layer against a real, fully migrated MySQL database.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const { Migrator } = require('../../src/database/migrator');
const { Database } = require('../../src/database/database');
const { createPool } = require('../../src/config/db');
const { UserRepository } = require('../../src/repositories/user.repository');
const { AccountRepository } = require('../../src/repositories/account.repository');
const { CategoryRepository } = require('../../src/repositories/category.repository');
const { TransactionRepository } = require('../../src/repositories/transaction.repository');
const { ReceiptRepository } = require('../../src/repositories/receipt.repository');
const { BudgetRepository } = require('../../src/repositories/budget.repository');
const { startMysql } = require('../helpers/mysql');

let mysql;
let pool;
let db;
let repos;
let userId;
let cashId;
let foodId;

test.before(async () => {
  mysql = await startMysql();
  const config = await mysql.createDatabase('repo');
  await new Migrator({ db: config, log: () => {} }).up();
  pool = createPool(config);
  db = new Database(pool);
  repos = {
    users: new UserRepository(db),
    accounts: new AccountRepository(db),
    categories: new CategoryRepository(db),
    transactions: new TransactionRepository(db),
    receipts: new ReceiptRepository(db),
    budgets: new BudgetRepository(db),
  };
  userId = await repos.users.create({
    fullName: 'Repo Tester',
    email: 'repo@example.com',
    passwordHash: 'x',
    currencyCode: 'USD',
    currencySymbol: '$',
    country: null,
  });
  cashId = await repos.accounts.create(userId, { name: 'Cash', type: 'cash', openingBalance: 100 });
  foodId = await repos.categories.create(userId, { name: 'Food & Dining', icon: 'restaurant', color: '#F59E0B', isExpense: true });
});

test.after(async () => {
  await pool?.end();
  await mysql?.stop();
});

const tx = (overrides = {}) => ({
  accountId: cashId,
  categoryId: foodId,
  title: 'Lunch',
  amount: 10,
  type: 'expense',
  note: null,
  tags: null,
  date: new Date('2026-11-03T12:00:00Z'),
  ...overrides,
});

test('TransactionRepository: create + findById joins account, category and receipt', async () => {
  const id = await repos.transactions.create(userId, tx({ title: 'Pizza', amount: 18.4 }));
  await repos.receipts.upsert(id, 'data:image/png;base64,iVBOR');
  const row = await repos.transactions.findById(id, userId);
  assert.equal(row.title, 'Pizza');
  assert.equal(row.amount, 18.4);
  assert.equal(row.account_name, 'Cash');
  assert.equal(row.category_name, 'Food & Dining');
  assert.equal(row.receipt_url, 'data:image/png;base64,iVBOR');
});

test('TransactionRepository: rows of other users are invisible', async () => {
  const id = await repos.transactions.create(userId, tx());
  assert.equal(await repos.transactions.findById(id, userId + 1), null);
  assert.equal(await repos.transactions.delete(id, userId + 1), false);
});

test('TransactionRepository: deleting a transaction cascades to its receipt', async () => {
  const id = await repos.transactions.create(userId, tx());
  await repos.receipts.upsert(id, 'https://example.com/x.jpg');
  assert.equal(await repos.transactions.delete(id, userId), true);
  const left = await db.query('SELECT COUNT(*) AS c FROM transaction_receipts WHERE transaction_id = ?', [id]);
  assert.equal(left[0].c, 0);
});

test('TransactionRepository: list filters by type, search and date range', async () => {
  await repos.transactions.create(userId, tx({ title: 'Paycheck', amount: 900, type: 'income', date: new Date('2026-10-30T09:00:00Z') }));
  const incomes = await repos.transactions.list(userId, { type: 'income', limit: 50, offset: 0 });
  assert.deepEqual(
    incomes.map((r) => r.title),
    ['Paycheck'],
  );
  const searched = await repos.transactions.list(userId, { search: 'pizz', limit: 50, offset: 0 });
  assert.deepEqual(
    searched.map((r) => r.title),
    ['Pizza'],
  );
  const november = await repos.transactions.list(userId, { from: new Date('2026-11-01T00:00:00Z'), limit: 50, offset: 0 });
  assert.ok(november.every((r) => new Date(r.transaction_date) >= new Date('2026-11-01T00:00:00Z')));
});

test('AccountRepository: raw income/expense totals per account (balance computed by the service)', async () => {
  const [cash] = await repos.accounts.listWithTotals(userId);
  const sums = await db.query(
    `SELECT SUM(CASE WHEN type='income' THEN amount ELSE 0 END) AS i, SUM(CASE WHEN type='expense' THEN amount ELSE 0 END) AS e
       FROM transactions WHERE account_id = ?`,
    [cashId],
  );
  assert.equal(cash.opening_balance, 100);
  assert.equal(cash.income_total, sums[0].i);
  assert.equal(cash.expense_total, sums[0].e);
});

test('AccountRepository/CategoryRepository: name lookups prefer exact matches', async () => {
  await repos.accounts.create(userId, { name: 'Cash Savings', type: 'bank' });
  assert.equal(await repos.accounts.findIdByName(userId, 'cash'), cashId);
  assert.equal(await repos.categories.findIdByNameLike(userId, 'food', true), foodId);
});

test('BudgetRepository: returns every limit up to the month, oldest first', async () => {
  await repos.budgets.upsert(userId, foodId, '2026-09-01', 300);
  await repos.budgets.upsert(userId, foodId, '2026-11-01', 450);
  await repos.budgets.upsert(userId, foodId, '2026-12-01', 999);
  await repos.budgets.upsert(userId, foodId, '2026-11-01', 500); // upsert same month
  assert.deepEqual(await repos.budgets.listLimitsUpTo(userId, '2026-11-01'), [
    { categoryId: foodId, monthStart: '2026-09-01', limit: 300 },
    { categoryId: foodId, monthStart: '2026-11-01', limit: 500 },
  ]);
});

test('UserRepository: profile updates are limited to whitelisted columns', async () => {
  await repos.users.updateProfile(userId, { full_name: 'Renamed', dark_mode: 1 });
  const user = await repos.users.findById(userId);
  assert.equal(user.full_name, 'Renamed');
  assert.equal(user.dark_mode, 1);
  await assert.rejects(repos.users.updateProfile(userId, { password_hash: 'evil' }), /cannot be updated/);
});

test('Database.transaction: rolls back every repository write on error', async () => {
  const before = await repos.accounts.countForUser(userId);
  await assert.rejects(
    db.transaction(async (t) => {
      await repos.accounts.withDb(t).create(userId, { name: 'Temp', type: 'cash' });
      throw new Error('boom');
    }),
    /boom/,
  );
  assert.equal(await repos.accounts.countForUser(userId), before);
});
