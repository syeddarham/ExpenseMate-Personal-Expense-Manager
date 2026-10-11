const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { accountToJson } = require('../utils/serializers');

const ACCOUNT_TYPES = ['cash', 'bank', 'card', 'wallet'];

/** Account row + computed running balance (opening balance + income - expense). */
const ACCOUNT_SELECT = `
  SELECT a.*,
         a.opening_balance + COALESCE(SUM(CASE t.type WHEN 'income' THEN t.amount WHEN 'expense' THEN -t.amount END), 0) AS balance
    FROM accounts a
    LEFT JOIN transactions t ON t.account_id = a.id`;

async function loadAccount(id, userId) {
  const [rows] = await pool.query(`${ACCOUNT_SELECT} WHERE a.id = ? AND a.user_id = ? GROUP BY a.id`, [id, userId]);
  if (rows.length === 0) throw new HttpError(404, 'Account not found', 'NOT_FOUND');
  return rows[0];
}

/** GET /api/accounts */
const listAccounts = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`${ACCOUNT_SELECT} WHERE a.user_id = ? GROUP BY a.id ORDER BY a.id`, [req.user.id]);
  res.json({ accounts: rows.map(accountToJson) });
});

/** POST /api/accounts */
const createAccount = asyncHandler(async (req, res) => {
  const v = new Validator();
  const name = v.string(req.body.name, 'name', { max: 80 });
  const type = v.oneOf(req.body.type || 'cash', 'type', ACCOUNT_TYPES);
  const opening = req.body.opening_balance === undefined ? 0 : Number(req.body.opening_balance);
  if (!Number.isFinite(opening)) v.fail('opening_balance', 'opening_balance must be a number');
  v.assert();

  const [result] = await pool.query(
    'INSERT INTO accounts (user_id, name, type, opening_balance) VALUES (?, ?, ?, ?)',
    [req.user.id, name, type, opening],
  );
  res.status(201).json({ account: accountToJson(await loadAccount(result.insertId, req.user.id)) });
});

/** PUT /api/accounts/:id */
const updateAccount = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  const sets = [];
  const params = [];
  if (req.body.name !== undefined) {
    sets.push('name = ?');
    params.push(v.string(req.body.name, 'name', { max: 80 }));
  }
  if (req.body.type !== undefined) {
    sets.push('type = ?');
    params.push(v.oneOf(req.body.type, 'type', ACCOUNT_TYPES));
  }
  if (req.body.opening_balance !== undefined) {
    const n = Number(req.body.opening_balance);
    if (!Number.isFinite(n)) v.fail('opening_balance', 'opening_balance must be a number');
    sets.push('opening_balance = ?');
    params.push(n);
  }
  v.assert();

  await loadAccount(id, req.user.id);
  if (sets.length > 0) {
    await pool.query(`UPDATE accounts SET ${sets.join(', ')} WHERE id = ? AND user_id = ?`, [...params, id, req.user.id]);
  }
  res.json({ account: accountToJson(await loadAccount(id, req.user.id)) });
});

/** DELETE /api/accounts/:id */
const deleteAccount = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  v.assert();

  const [result] = await pool.query('DELETE FROM accounts WHERE id = ? AND user_id = ?', [id, req.user.id]);
  if (result.affectedRows === 0) throw new HttpError(404, 'Account not found', 'NOT_FOUND');
  res.json({ message: 'Account deleted' });
});

module.exports = { listAccounts, createAccount, updateAccount, deleteAccount };
