const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { userToJson } = require('../utils/serializers');

async function loadUser(id) {
  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [id]);
  if (rows.length === 0) throw new HttpError(404, 'User not found', 'NOT_FOUND');
  return rows[0];
}

/** GET /api/users/me */
const getMe = asyncHandler(async (req, res) => {
  res.json({ user: userToJson(await loadUser(req.user.id)) });
});

/** PUT /api/users/me  (any subset of profile + preference fields) */
const updateMe = asyncHandler(async (req, res) => {
  const b = req.body;
  const v = new Validator();
  const sets = [];
  const params = [];

  if (b.full_name !== undefined || b.name !== undefined) {
    const rawName = b.full_name !== undefined ? b.full_name : b.name;
    sets.push('full_name = ?');
    params.push(v.string(rawName, 'full_name', { min: 2, max: 120 }));
  }
  if (b.email !== undefined) {
    const newEmail = v.email(b.email);
    // Check if new email is already in use by another user
    const [dup] = await pool.query('SELECT id FROM users WHERE email = ? AND id <> ?', [newEmail, req.user.id]);
    if (dup.length > 0) {
      throw new HttpError(409, 'This email address is already in use by another account', 'EMAIL_TAKEN');
    }
    sets.push('email = ?');
    params.push(newEmail);
  }
  if (b.avatar_url !== undefined || b.avatar_data !== undefined) {
    const avatar = b.avatar_url !== undefined ? b.avatar_url : b.avatar_data;
    sets.push('avatar_url = ?');
    params.push(avatar ? String(avatar) : null);
  }
  if (b.primary_color !== undefined) {
    const color = v.string(b.primary_color, 'primary_color', { min: 4, max: 10 });
    sets.push('primary_color = ?');
    params.push(color);
  }
  if (b.country !== undefined) {
    sets.push('country = ?');
    params.push(v.string(b.country, 'country', { max: 100 }));
  }
  if (b.preferred_currency !== undefined) {
    const code = v.string(b.preferred_currency, 'preferred_currency', { min: 3, max: 3 });
    sets.push('currency_code = ?');
    params.push(code ? code.toUpperCase() : code);
  }
  if (b.currency_symbol !== undefined) {
    sets.push('currency_symbol = ?');
    params.push(v.string(b.currency_symbol, 'currency_symbol', { max: 10 }));
  }
  if (b.dark_mode !== undefined) {
    sets.push('dark_mode = ?');
    params.push(b.dark_mode ? 1 : 0);
  }
  if (b.biometric_enabled !== undefined) {
    sets.push('biometric_enabled = ?');
    params.push(b.biometric_enabled ? 1 : 0);
  }
  v.assert();

  if (sets.length > 0) {
    await pool.query(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`, [...params, req.user.id]);
  }
  res.json({ user: userToJson(await loadUser(req.user.id)) });
});

/** PUT /api/users/me/password */
const changePassword = asyncHandler(async (req, res) => {
  const v = new Validator();
  const current = v.string(req.body.current_password, 'current_password', { max: 100 });
  const next = v.password(req.body.new_password, 'new_password');
  v.assert();

  const user = await loadUser(req.user.id);
  if (!(await bcrypt.compare(current, user.password_hash))) {
    throw new HttpError(400, 'Current password is incorrect', 'INVALID_CREDENTIALS');
  }
  await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [await bcrypt.hash(next, 10), user.id]);
  res.json({ message: 'Password updated successfully' });
});

/** PUT /api/users/me/currency */
const convertCurrency = asyncHandler(async (req, res) => {
  const v = new Validator();
  const currencyCode = v.string(req.body.currency_code, 'currency_code', { min: 2, max: 10 }).toUpperCase();
  const currencySymbol = v.string(req.body.currency_symbol, 'currency_symbol', { min: 1, max: 10 });
  const convertAmounts = req.body.convert_amounts === true;
  const rate = convertAmounts ? v.positiveNumber(req.body.rate, 'rate') : 1.0;
  v.assert();

  const user = await loadUser(req.user.id);
  const currentCode = (user.currency_code || 'USD').toUpperCase();
  const isSameCurrency = currentCode === currencyCode;
  const shouldConvert = convertAmounts && !isSameCurrency && rate !== 1.0;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    if (shouldConvert) {
      await conn.query('UPDATE accounts SET opening_balance = ROUND(opening_balance * ?, 2) WHERE user_id = ?', [rate, req.user.id]);
      await conn.query('UPDATE transactions SET amount = ROUND(amount * ?, 2) WHERE user_id = ?', [rate, req.user.id]);
      await conn.query('UPDATE budgets SET limit_amount = ROUND(limit_amount * ?, 2) WHERE user_id = ?', [rate, req.user.id]);
    }
    await conn.query('UPDATE users SET currency_code = ?, currency_symbol = ? WHERE id = ?', [currencyCode, currencySymbol, req.user.id]);
    await conn.commit();
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }

  res.json({
    message: convertAmounts ? 'Currency converted successfully' : 'Currency updated successfully',
    user: userToJson(await loadUser(req.user.id)),
  });
});

module.exports = { getMe, updateMe, changePassword, convertCurrency };
