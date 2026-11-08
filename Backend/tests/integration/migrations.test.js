/**
 * Migration 001 -> 002 against a real MySQL server.
 * Proves: the migration is repeatable, keeps every existing record intact,
 * moves receipts, fixes defect D1 (large receipts), and can be rolled back.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { Migrator } = require('../../src/database/migrator');
const { takeSnapshot, compare } = require('../../scripts/verify-migration');
const { startMysql } = require('../helpers/mysql');

const REAL_DIR = path.join(__dirname, '..', '..', 'Database', 'migrations');
const quiet = () => {};
let mysql;

test.before(async () => {
  mysql = await startMysql();
});
test.after(async () => {
  await mysql?.stop();
});

/** A copy of the migrations folder containing only the given versions. */
function migrationsUpTo(version) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'mig-'));
  for (const f of fs.readdirSync(REAL_DIR)) {
    if (f.slice(0, 3) <= version) fs.copyFileSync(path.join(REAL_DIR, f), path.join(dir, f));
  }
  return dir;
}

/** Assignment 01-style data, including a short receipt URL that fit the old column. */
async function seedAssignment01Data(conn) {
  await conn.query(`
    INSERT INTO users (id, full_name, email, password_hash, email_verified) VALUES
      (1, 'Alice', 'alice@example.com', 'hash-a', 1), (2, 'Bob', 'bob@example.com', 'hash-b', 1);
    INSERT INTO accounts (id, user_id, name, type, opening_balance) VALUES
      (1, 1, 'Cash', 'cash', 50.00), (2, 2, 'Bank Account', 'bank', 1000.00);
    INSERT INTO categories (id, user_id, name, icon, color, is_expense) VALUES
      (1, 1, 'Groceries', 'shopping_cart', '#10B981', 1), (2, 2, 'Salary / Income', 'attach_money', '#059669', 0);
    INSERT INTO transactions (id, user_id, account_id, category_id, title, amount, type, note, tags, receipt_url, transaction_date) VALUES
      (1, 1, 1, 1, 'Weekly shop', 42.75, 'expense', 'milk, eggs', 'food,home', 'https://cdn.example.com/r/1.jpg', '2026-10-03 10:15:00'),
      (2, 1, 1, 1, 'Snacks', 3.10, 'expense', NULL, NULL, NULL, '2026-10-04 18:00:00'),
      (3, 2, 2, 2, 'October salary', 3200.00, 'income', NULL, NULL, '', '2026-10-28 09:00:00');
    INSERT INTO budgets (user_id, category_id, month_start, limit_amount) VALUES (1, 1, '2026-10-01', 400.00);
  `);
}

test('fresh database: all migrations apply in order and a second run is a no-op', async () => {
  const db = await mysql.createDatabase('fresh');
  const migrator = new Migrator({ db, log: quiet });
  assert.deepEqual(await migrator.up(), ['001', '002']);
  assert.deepEqual(await migrator.up(), []);
  const status = await migrator.status();
  assert.ok(status.every((m) => m.applied && m.checksumMatches));
});

test('existing Assignment 01 database: records are preserved and receipts are moved', async () => {
  const db = await mysql.createDatabase('a01');
  await new Migrator({ db, dir: migrationsUpTo('001'), log: quiet }).up();
  const conn = await mysql.connect(db);
  await seedAssignment01Data(conn);

  const before = await takeSnapshot(db);
  assert.equal(before.receipts.location, 'transactions.receipt_url');
  assert.equal(before.receipts.count, 1);

  assert.deepEqual(await new Migrator({ db, log: quiet }).up(), ['002']);

  const after = await takeSnapshot(db);
  const { problems, report } = compare(before, after);
  assert.deepEqual(problems, [], report.join('\n'));
  assert.equal(after.receipts.location, 'transaction_receipts');

  const [[receipt]] = await conn.query('SELECT content FROM transaction_receipts WHERE transaction_id = 1');
  assert.equal(receipt.content, 'https://cdn.example.com/r/1.jpg');
  const [cols] = await conn.query("SHOW COLUMNS FROM transactions LIKE 'receipt_url'");
  assert.equal(cols.length, 0, 'old column dropped');
  await conn.end();
});

test('defect D1: a 200 KB base64 receipt fails on the old schema and is stored after migration 002', async () => {
  const receipt = `data:image/jpeg;base64,${'A'.repeat(200_000)}`;

  const oldDb = await mysql.createDatabase('old');
  await new Migrator({ db: oldDb, dir: migrationsUpTo('001'), log: quiet }).up();
  const oldConn = await mysql.connect(oldDb);
  await seedAssignment01Data(oldConn);
  await assert.rejects(oldConn.query('UPDATE transactions SET receipt_url = ? WHERE id = 2', [receipt]), {
    code: 'ER_DATA_TOO_LONG',
  });
  await oldConn.end();

  const newDb = await mysql.createDatabase('new');
  await new Migrator({ db: newDb, log: quiet }).up();
  const newConn = await mysql.connect(newDb);
  await newConn.query(`
    INSERT INTO users (id, full_name, email, password_hash) VALUES (1, 'Alice', 'alice@example.com', 'hash-a');
    INSERT INTO accounts (id, user_id, name) VALUES (1, 1, 'Cash');
    INSERT INTO categories (id, user_id, name) VALUES (1, 1, 'Groceries');
    INSERT INTO transactions (id, user_id, account_id, category_id, title, amount, type, transaction_date)
      VALUES (2, 1, 1, 1, 'Snacks', 3.10, 'expense', '2026-10-04 18:00:00');
  `);
  await newConn.query('INSERT INTO transaction_receipts (transaction_id, content) VALUES (2, ?)', [receipt]);
  const [[row]] = await newConn.query('SELECT CHAR_LENGTH(content) AS len FROM transaction_receipts WHERE transaction_id = 2');
  assert.equal(row.len, receipt.length);
  await newConn.end();
});

test('rollback: down restores receipt_url and copies back receipts that fit', async () => {
  const db = await mysql.createDatabase('down');
  await new Migrator({ db, dir: migrationsUpTo('001'), log: quiet }).up();
  const conn = await mysql.connect(db);
  await seedAssignment01Data(conn);
  const migrator = new Migrator({ db, log: quiet });
  await migrator.up();

  assert.equal(await migrator.down(), '002');
  const [rows] = await conn.query('SELECT id, receipt_url FROM transactions ORDER BY id');
  assert.deepEqual(
    rows.map((r) => r.receipt_url),
    ['https://cdn.example.com/r/1.jpg', null, null],
  );
  const [tables] = await conn.query("SHOW TABLES LIKE 'transaction_receipts'");
  assert.equal(tables.length, 0);
  await conn.end();

  assert.deepEqual(await migrator.up(), ['002'], 'can be re-applied after rollback');
});

test('an applied migration that was edited afterwards is refused', async () => {
  const db = await mysql.createDatabase('drift');
  const dir = migrationsUpTo('002');
  await new Migrator({ db, dir, log: quiet }).up();
  fs.appendFileSync(path.join(dir, '001_baseline_schema.up.sql'), '\n-- edited later\n');
  await assert.rejects(new Migrator({ db, dir, log: quiet }).up(), /checksum mismatch/);
});
