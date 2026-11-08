/**
 * System / regression tests: complete ExpenseMate workflows over HTTP,
 * exactly as the Flutter app calls the API.
 *
 * Test names starting with [D1]/[D2]/[D3] cover defects found during
 * Assignment 02; they are EXPECTED to fail when this suite is run against
 * the Assignment 01 baseline and to pass on the current code.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const { startHarness, createClient } = require('./harness');

let harness;
let api;
let userCounter = 0;

test.before(async () => {
  harness = await startHarness();
  api = createClient(harness.baseUrl);
  console.log(`# system tests running against: ${harness.label}`);
});

test.after(async () => {
  await harness?.stop();
});

const PASSWORD = 'Secret123!';
const thisMonth = () => new Date().toISOString().slice(0, 7);
const nextMonth = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth() + 1, 15).toISOString().slice(0, 7);
};

/** Registers, verifies and returns { email, token, user, categories, accounts }. */
async function newUser(name = 'Test User') {
  const email = `user${++userCounter}.${Date.now()}@example.com`;
  const reg = await api('POST', '/auth/register', { body: { full_name: name, email, password: PASSWORD } });
  assert.equal(reg.status, 201, JSON.stringify(reg.body));
  const code = await harness.lastCode(email, 'email_verification');
  const verified = await api('POST', '/auth/verify-email', { body: { email, code } });
  assert.equal(verified.status, 200, JSON.stringify(verified.body));
  const token = verified.body.token;
  const categories = (await api('GET', '/categories', { token })).body.categories;
  const accounts = (await api('GET', '/accounts', { token })).body.accounts;
  return { email, token, user: verified.body.user, categories, accounts };
}

const category = (u, name) => u.categories.find((c) => c.name === name);
const account = (u, name) => u.accounts.find((a) => a.name === name);

test('ST-01 Registration: register -> e-mail code -> verify -> login -> profile', async () => {
  const email = `st01.${Date.now()}@example.com`;
  const reg = await api('POST', '/auth/register', { body: { full_name: 'Sara Test', email, password: PASSWORD } });
  assert.equal(reg.status, 201);

  const wrong = await api('POST', '/auth/verify-email', { body: { email, code: '000000' } });
  assert.equal(wrong.status, 400);

  const code = await harness.lastCode(email, 'email_verification');
  const verified = await api('POST', '/auth/verify-email', { body: { email, code } });
  assert.equal(verified.status, 200);
  assert.equal(verified.body.user.email_verified, true);

  const login = await api('POST', '/auth/login', { body: { email, password: PASSWORD } });
  assert.equal(login.status, 200);
  const me = await api('GET', '/users/me', { token: login.body.token });
  assert.equal(me.body.user.name, 'Sara Test');
  assert.equal(me.body.user.preferred_currency, 'USD');

  const accounts = await api('GET', '/accounts', { token: login.body.token });
  assert.deepEqual(
    accounts.body.accounts.map((a) => a.name),
    ['Cash', 'Bank Account', 'Debit Card', 'Credit Card', 'Digital Wallet'],
  );
});

test('ST-02 Access control: unverified login is blocked, protected routes need a valid token', async () => {
  const email = `st02.${Date.now()}@example.com`;
  await api('POST', '/auth/register', { body: { full_name: 'No Verify', email, password: PASSWORD } });
  const login = await api('POST', '/auth/login', { body: { email, password: PASSWORD } });
  assert.equal(login.status, 403);
  assert.equal(login.body.error.code, 'EMAIL_NOT_VERIFIED');

  assert.equal((await api('GET', '/transactions')).status, 401);
  assert.equal((await api('GET', '/transactions', { token: 'not-a-jwt' })).status, 401);
  assert.equal((await api('POST', '/auth/login', { body: { email, password: 'wrong-password' } })).status, 401);
});

test('ST-03 Password reset: forgot -> code -> reset -> login with the new password only', async () => {
  const u = await newUser();
  const forgot = await api('POST', '/auth/forgot-password', { body: { email: u.email } });
  assert.equal(forgot.status, 200);
  const code = await harness.lastCode(u.email, 'password_reset');

  const reset = await api('POST', '/auth/reset-password', { body: { email: u.email, code, new_password: 'BrandNew456!' } });
  assert.equal(reset.status, 200);
  assert.equal((await api('POST', '/auth/login', { body: { email: u.email, password: PASSWORD } })).status, 401);
  assert.equal((await api('POST', '/auth/login', { body: { email: u.email, password: 'BrandNew456!' } })).status, 200);
});

test('ST-04 Add Expense / Income: saved, listed, and reflected in balances and the dashboard', async () => {
  const u = await newUser();
  const groceries = category(u, 'Groceries');
  const salary = category(u, 'Salary / Income');

  const expense = await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Weekly shop', amount: 46.8, type: 'expense', category_id: groceries.id, account: 'Cash', note: 'milk', date: new Date().toISOString() },
  });
  assert.equal(expense.status, 201, JSON.stringify(expense.body));
  assert.equal(expense.body.transaction.category.name, 'Groceries');
  assert.equal(expense.body.transaction.account, 'Cash');

  const income = await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Salary', amount: 1500, type: 'income', category_id: salary.id, account: 'Bank Account', date: new Date().toISOString() },
  });
  assert.equal(income.status, 201);

  const list = await api('GET', '/transactions', { token: u.token });
  assert.equal(list.body.transactions.length, 2);
  const onlyExpenses = await api('GET', '/transactions?type=expense', { token: u.token });
  assert.deepEqual(
    onlyExpenses.body.transactions.map((t) => t.title),
    ['Weekly shop'],
  );

  const accounts = (await api('GET', '/accounts', { token: u.token })).body.accounts;
  assert.equal(accounts.find((a) => a.name === 'Cash').balance, -46.8);
  assert.equal(accounts.find((a) => a.name === 'Bank Account').balance, 1500);

  const overview = await api('GET', '/overview', { token: u.token });
  assert.equal(overview.body.total_balance, 1453.2);
  assert.equal(overview.body.total_income, 1500);
  assert.equal(overview.body.total_expense, 46.8);
  assert.equal(overview.body.recent_transactions.length, 2);
});

test('ST-05 Edit and delete a transaction', async () => {
  const u = await newUser();
  const created = await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Taxi', amount: 20, type: 'expense', category_id: category(u, 'Transport').id, account: 'Cash' },
  });
  const id = created.body.transaction.id;

  const updated = await api('PUT', `/transactions/${id}`, {
    token: u.token,
    body: { title: 'Taxi home', amount: 25.5, type: 'expense', category_id: category(u, 'Transport').id, account: 'Cash' },
  });
  assert.equal(updated.status, 200);
  assert.equal(updated.body.transaction.amount, 25.5);
  assert.equal((await api('GET', `/transactions/${id}`, { token: u.token })).body.transaction.title, 'Taxi home');

  assert.equal((await api('DELETE', `/transactions/${id}`, { token: u.token })).status, 200);
  assert.equal((await api('GET', `/transactions/${id}`, { token: u.token })).status, 404);
  const cash = (await api('GET', '/accounts', { token: u.token })).body.accounts.find((a) => a.name === 'Cash');
  assert.equal(cash.balance, 0);
});

test('ST-06 Monthly Budget Summary: limits, spending and carry-forward to the next month', async () => {
  const u = await newUser();
  const food = category(u, 'Food & Dining');

  const set = await api('PUT', `/budgets/${food.id}`, { token: u.token, body: { limit_amount: 300, month: thisMonth() } });
  assert.equal(set.status, 200, JSON.stringify(set.body));
  assert.equal(set.body.budget.limit_amount, 300);

  await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Dinner', amount: 120.25, type: 'expense', category_id: food.id, account: 'Cash', date: new Date().toISOString() },
  });

  const budgets = (await api('GET', `/budgets?month=${thisMonth()}`, { token: u.token })).body.budgets;
  const foodBudget = budgets.find((b) => b.category.id === food.id);
  assert.equal(foodBudget.limit_amount, 300);
  assert.equal(foodBudget.spent_amount, 120.25);
  assert.ok(budgets.every((b) => b.category.is_expense), 'only expense categories have budgets');

  const next = (await api('GET', `/budgets?month=${nextMonth()}`, { token: u.token })).body.budgets;
  const nextFood = next.find((b) => b.category.id === food.id);
  assert.equal(nextFood.limit_amount, 300, 'limit carries forward');
  assert.equal(nextFood.spent_amount, 0, 'spending does not');

  const income = await api('PUT', `/budgets/${category(u, 'Freelance').id}`, { token: u.token, body: { limit_amount: 10 } });
  assert.equal(income.status, 404, 'income categories cannot have budgets');
});

test('[D2] ST-07 Dashboard total budget counts each category once after a limit is changed', async () => {
  const u = await newUser();
  const food = category(u, 'Food & Dining');
  const prev = new Date(new Date().getFullYear(), new Date().getMonth() - 1, 15).toISOString().slice(0, 7);
  await api('PUT', `/budgets/${food.id}`, { token: u.token, body: { limit_amount: 200, month: prev } });
  await api('PUT', `/budgets/${food.id}`, { token: u.token, body: { limit_amount: 350, month: thisMonth() } });
  await api('PUT', `/budgets/${category(u, 'Transport').id}`, { token: u.token, body: { limit_amount: 100, month: thisMonth() } });

  const overview = await api('GET', '/overview', { token: u.token });
  assert.equal(overview.body.total_budget, 450, 'expected 350 (food, current limit) + 100 (transport)');
});

test('ST-08 Categories: create, reject duplicates, protect categories in use, delete unused', async () => {
  const u = await newUser();
  const created = await api('POST', '/categories', { token: u.token, body: { name: 'Pets', icon: 'pets', color: '#AA5500', is_expense: true } });
  assert.equal(created.status, 201);
  assert.equal(created.body.category.is_custom, true);

  const dup = await api('POST', '/categories', { token: u.token, body: { name: 'pets', icon: 'pets', color: '#AA5500' } });
  assert.equal(dup.status, 400);
  assert.equal(dup.body.error.code, 'DUPLICATE_CATEGORY');

  await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Vet', amount: 60, type: 'expense', category_id: created.body.category.id, account: 'Cash' },
  });
  const inUse = await api('DELETE', `/categories/${created.body.category.id}`, { token: u.token });
  assert.equal(inUse.status, 400);
  assert.equal(inUse.body.error.code, 'CATEGORY_IN_USE');

  const spare = await api('POST', '/categories', { token: u.token, body: { name: 'Hobbies', icon: 'brush', color: '#123456' } });
  assert.equal((await api('DELETE', `/categories/${spare.body.category.id}`, { token: u.token })).status, 200);
});

test('ST-09 Analytics: category breakdown percentages and trend match the totals', async () => {
  const u = await newUser();
  const now = new Date().toISOString();
  for (const [name, amount] of [
    ['Food & Dining', 30],
    ['Transport', 10],
    ['Food & Dining', 20],
  ]) {
    await api('POST', '/transactions', {
      token: u.token,
      body: { title: name, amount, type: 'expense', category_id: category(u, name).id, account: 'Cash', date: now },
    });
  }
  const res = await api('GET', '/analytics?period=month', { token: u.token });
  assert.equal(res.status, 200);
  assert.equal(res.body.total_expense, 60);
  assert.deepEqual(
    res.body.category_spending.map((c) => [c.category.name, c.amount, c.percentage]),
    [
      ['Food & Dining', 50, 83.3],
      ['Transport', 10, 16.7],
    ],
  );
  const trendTotal = res.body.trend.reduce((s, b) => s + b.expense, 0);
  assert.equal(trendTotal, 60);
});

test('ST-10 Export: CSV statement is generated without e-mail', async () => {
  const u = await newUser();
  await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Books', amount: 15, type: 'expense', category_id: category(u, 'Education').id, account: 'Cash' },
  });
  const res = await api('POST', '/transactions/export', { token: u.token, body: { format: 'csv', send_email: false } });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  assert.equal(res.body.recordCount, 1);
  assert.equal(res.body.emailSent, false);
  const csv = Buffer.from(res.body.base64, 'base64').toString('utf8').split('\r\n');
  assert.equal(csv[0], 'ID,Date,Type,Category,Account,Amount ($),Note,Tags');
  assert.equal(csv.length, 2);
});

test('[D3] ST-11 Export: account names are filled in and tagged transactions do not crash the export', async () => {
  const u = await newUser();
  await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Lunch', amount: 9.5, type: 'expense', category_id: category(u, 'Food & Dining').id, account: 'Debit Card', tags: 'work,food' },
  });
  const res = await api('POST', '/transactions/export', { token: u.token, body: { format: 'csv', send_email: false } });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  const row = Buffer.from(res.body.base64, 'base64').toString('utf8').split('\r\n')[1];
  assert.match(row, /"Debit Card"/);
  assert.match(row, /"work, food"$/);
});

test('[D1] ST-12 Receipts: a photographed receipt (base64 image, ~150 KB) is saved and returned', async () => {
  const u = await newUser();
  const receipt = `data:image/jpeg;base64,${'Q'.repeat(150_000)}`;
  const created = await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Hardware store', amount: 33, type: 'expense', category_id: category(u, 'Shopping').id, account: 'Cash', receipt_url: receipt },
  });
  assert.equal(created.status, 201, JSON.stringify(created.body).slice(0, 300));
  const fetched = await api('GET', `/transactions/${created.body.transaction.id}`, { token: u.token });
  assert.equal(fetched.body.transaction.receipt_url, receipt);
});

test('ST-13 Settings: currency change converts every stored amount', async () => {
  const u = await newUser();
  await api('POST', '/transactions', {
    token: u.token,
    body: { title: 'Rent', amount: 100, type: 'expense', category_id: category(u, 'Bills & Utilities').id, account: 'Bank Account' },
  });
  await api('PUT', `/budgets/${category(u, 'Bills & Utilities').id}`, { token: u.token, body: { limit_amount: 200 } });

  const res = await api('PUT', '/users/me/currency', {
    token: u.token,
    body: { currency_code: 'eur', currency_symbol: '€', convert_amounts: true, rate: 0.5 },
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.user.preferred_currency, 'EUR');
  const tx = (await api('GET', '/transactions', { token: u.token })).body.transactions[0];
  assert.equal(tx.amount, 50);
  const budget = (await api('GET', '/budgets', { token: u.token })).body.budgets.find((b) => b.title === 'Bills & Utilities');
  assert.equal(budget.limit_amount, 100);
});

test('ST-15 Profile: update name and preferences, change password, reject a taken e-mail', async () => {
  const u = await newUser();
  const other = await newUser('Other');

  const updated = await api('PUT', '/users/me', {
    token: u.token,
    body: { name: 'Renamed User', primary_color: '#2563EB', country: 'Pakistan', preferred_currency: 'pkr', currency_symbol: 'Rs', dark_mode: true },
  });
  assert.equal(updated.status, 200, JSON.stringify(updated.body));
  assert.equal(updated.body.user.name, 'Renamed User');
  assert.equal(updated.body.user.primary_color, '#2563EB');
  assert.equal(updated.body.user.country, 'Pakistan');
  assert.equal(updated.body.user.preferred_currency, 'PKR');
  assert.equal(updated.body.user.dark_mode, true);

  const taken = await api('PUT', '/users/me', { token: u.token, body: { email: other.email } });
  assert.equal(taken.status, 409);

  const badName = await api('PUT', '/users/me', { token: u.token, body: { full_name: 'x' } });
  assert.equal(badName.status, 400);

  const wrong = await api('PUT', '/users/me/password', { token: u.token, body: { current_password: 'nope', new_password: 'Another789!' } });
  assert.equal(wrong.status, 400);
  const changed = await api('PUT', '/users/me/password', { token: u.token, body: { current_password: PASSWORD, new_password: 'Another789!' } });
  assert.equal(changed.status, 200);
  assert.equal((await api('POST', '/auth/login', { body: { email: u.email, password: 'Another789!' } })).status, 200);
});

test('ST-14 Accounts: create, rename, delete; other users cannot see them', async () => {
  const u = await newUser();
  const other = await newUser('Other');
  const created = await api('POST', '/accounts', { token: u.token, body: { name: 'Savings', type: 'bank', opening_balance: 250 } });
  assert.equal(created.status, 201);
  assert.equal(created.body.account.balance, 250);
  const id = created.body.account.id;

  const renamed = await api('PUT', `/accounts/${id}`, { token: u.token, body: { name: 'Holiday fund' } });
  assert.equal(renamed.body.account.name, 'Holiday fund');
  assert.equal((await api('PUT', `/accounts/${id}`, { token: other.token, body: { name: 'hack' } })).status, 404);
  assert.equal((await api('DELETE', `/accounts/${id}`, { token: other.token })).status, 404);
  assert.equal((await api('DELETE', `/accounts/${id}`, { token: u.token })).status, 200);
});
