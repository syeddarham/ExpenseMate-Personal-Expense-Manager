#!/usr/bin/env node
/**
 * Proves a migration kept existing records correct.
 *
 *   node scripts/verify-migration.js snapshot <file>   (before migrating)
 *   node scripts/verify-migration.js verify   <file>   (after migrating)
 *
 * The snapshot stores row counts and a SHA-256 fingerprint of every row of
 * every business table (receipts are fingerprinted wherever they live:
 * transactions.receipt_url before migration 002, transaction_receipts after).
 * Only hashes and counts are written, so no personal data leaves the DB.
 */
const crypto = require('crypto');
const fs = require('fs');
const mysql = require('mysql2/promise');
const env = require('../src/config/env');

const TABLES = {
  users: 'SELECT id, full_name, email, password_hash, currency_code, currency_symbol, country, email_verified FROM users ORDER BY id',
  accounts: 'SELECT id, user_id, name, type, opening_balance FROM accounts ORDER BY id',
  categories: 'SELECT id, user_id, name, icon, color, is_expense FROM categories ORDER BY id',
  transactions: `SELECT id, user_id, account_id, category_id, title, amount, type, note, tags,
                        DATE_FORMAT(transaction_date, '%Y-%m-%d %H:%i:%s') AS transaction_date
                   FROM transactions ORDER BY id`,
  budgets: "SELECT id, user_id, category_id, DATE_FORMAT(month_start, '%Y-%m-%d') AS month_start, limit_amount FROM budgets ORDER BY id",
};

const hash = (value) => crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');

async function receipts(conn) {
  const [[{ hasTable }]] = await conn.query(
    "SELECT COUNT(*) AS hasTable FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'transaction_receipts'",
  );
  const sql = hasTable
    ? 'SELECT transaction_id AS id, content FROM transaction_receipts ORDER BY transaction_id'
    : "SELECT id, receipt_url AS content FROM transactions WHERE receipt_url IS NOT NULL AND receipt_url <> '' ORDER BY id";
  const [rows] = await conn.query(sql);
  return { location: hasTable ? 'transaction_receipts' : 'transactions.receipt_url', rows };
}

/** @param {object} [db] connection settings; defaults to the .env database */
async function takeSnapshot(db = env.db) {
  const conn = await mysql.createConnection({
    host: db.host,
    port: db.port,
    user: db.user,
    password: db.password,
    database: db.name,
    decimalNumbers: true,
    dateStrings: true,
  });
  try {
    const snapshot = { database: db.name, takenAt: new Date().toISOString(), tables: {} };
    for (const [table, sql] of Object.entries(TABLES)) {
      const [rows] = await conn.query(sql);
      snapshot.tables[table] = { count: rows.length, rows: Object.fromEntries(rows.map((r) => [r.id, hash(r)])) };
    }
    const r = await receipts(conn);
    snapshot.receipts = {
      location: r.location,
      count: r.rows.length,
      rows: Object.fromEntries(r.rows.map((x) => [x.id, hash(x.content)])),
    };
    return snapshot;
  } finally {
    await conn.end();
  }
}

function compare(before, after) {
  const problems = [];
  const report = [];
  const sections = { ...before.tables, receipts: before.receipts };
  for (const [name, b] of Object.entries(sections)) {
    const a = name === 'receipts' ? after.receipts : after.tables[name];
    let changed = 0;
    let missing = 0;
    for (const [id, digest] of Object.entries(b.rows)) {
      if (!(id in a.rows)) missing++;
      else if (a.rows[id] !== digest) changed++;
    }
    const ok = missing === 0 && changed === 0 && a.count >= b.count;
    report.push(
      `  ${ok ? 'PASS' : 'FAIL'}  ${name.padEnd(13)} before=${String(b.count).padStart(4)}  after=${String(a.count).padStart(4)}  missing=${missing}  changed=${changed}`,
    );
    if (!ok) problems.push(name);
  }
  if (before.receipts.location !== after.receipts.location) {
    report.push(`  INFO  receipts moved: ${before.receipts.location} -> ${after.receipts.location}`);
  }
  return { problems, report };
}

async function main() {
  const [mode, file] = process.argv.slice(2);
  if (!['snapshot', 'verify'].includes(mode) || !file) {
    console.error('Usage: verify-migration.js snapshot|verify <file>');
    process.exit(2);
  }
  const current = await takeSnapshot();
  if (mode === 'snapshot') {
    fs.writeFileSync(file, JSON.stringify(current, null, 2));
    const counts = Object.entries(current.tables)
      .map(([t, v]) => `${t}=${v.count}`)
      .join(' ');
    console.log(`[verify] Snapshot saved to ${file}: ${counts} receipts=${current.receipts.count} (${current.receipts.location})`);
    return;
  }
  const before = JSON.parse(fs.readFileSync(file, 'utf8'));
  const { problems, report } = compare(before, current);
  console.log(`[verify] Comparing ${before.takenAt} snapshot with current database:`);
  console.log(report.join('\n'));
  if (problems.length) {
    console.error(`[verify] FAILED: ${problems.join(', ')}`);
    process.exit(1);
  }
  console.log('[verify] OK - every pre-migration record is present and unchanged.');
}

if (require.main === module) {
  main().catch((err) => {
    console.error('[verify] ERROR:', err.message);
    process.exit(1);
  });
}

module.exports = { takeSnapshot, compare };
