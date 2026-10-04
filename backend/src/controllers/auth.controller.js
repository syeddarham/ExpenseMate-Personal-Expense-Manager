const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { userToJson } = require('../utils/serializers');
const { signToken } = require('../middleware/auth');
const { issueCode, consumeCode } = require('../services/codes');
const { seedDefaultCategoriesForUser } = require('./category.controller');

const DEFAULT_ACCOUNTS = [
  ['Cash', 'cash'],
  ['Bank Account', 'bank'],
  ['Debit Card', 'card'],
  ['Credit Card', 'card'],
  ['Digital Wallet', 'wallet'],
];

async function findUserByEmail(email) {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0];
}

/** POST /api/auth/register */
const register = asyncHandler(async (req, res) => {
  const v = new Validator();
  const fullName = v.string(req.body.full_name, 'full_name', { min: 2, max: 120 });
  const email = v.email(req.body.email);
  const password = v.password(req.body.password);
  v.assert();

  const currencyCode = (req.body.currency_code || 'USD').toString().toUpperCase().slice(0, 10);
  const currencySymbol = (req.body.currency_symbol || '$').toString().slice(0, 10);
  const country = req.body.country ? req.body.country.toString().slice(0, 80) : null;

  const passwordHash = await bcrypt.hash(password, 10);
  let user = await findUserByEmail(email);

  if (user && user.email_verified) {
    throw new HttpError(409, 'An account with this email already exists', 'EMAIL_TAKEN');
  }

  if (user) {
    // Unverified account re-registering: refresh credentials and resend the code
    await pool.query(
      'UPDATE users SET full_name = ?, password_hash = ?, currency_code = ?, currency_symbol = ?, country = COALESCE(?, country) WHERE id = ?',
      [fullName, passwordHash, currencyCode, currencySymbol, country, user.id],
    );
  } else {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const [result] = await conn.query(
        'INSERT INTO users (full_name, email, password_hash, currency_code, currency_symbol, country) VALUES (?, ?, ?, ?, ?, ?)',
        [fullName, email, passwordHash, currencyCode, currencySymbol, country],
      );
      const userId = result.insertId;
      for (const [name, type] of DEFAULT_ACCOUNTS) {
        await conn.query('INSERT INTO accounts (user_id, name, type) VALUES (?, ?, ?)', [userId, name, type]);
      }
      await seedDefaultCategoriesForUser(userId, conn);
      await conn.commit();
      user = { id: userId, email };
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  const code = await issueCode(user, 'email_verification');
  res.status(201).json({
    message: 'Account created. A verification code has been sent to your email.',
    email,
    debug_code: code,
  });
});

/** POST /api/auth/verify-email */
const verifyEmail = asyncHandler(async (req, res) => {
  const v = new Validator();
  const email = v.email(req.body.email);
  const code = v.string(req.body.code, 'code', { min: 6, max: 6 });
  v.assert();

  const user = await findUserByEmail(email);
  if (!user) throw new HttpError(404, 'Account not found', 'NOT_FOUND');

  await consumeCode(user.id, 'email_verification', code);
  await pool.query('UPDATE users SET email_verified = 1 WHERE id = ?', [user.id]);
  user.email_verified = 1;

  res.json({ token: signToken(user.id), user: userToJson(user) });
});

/** POST /api/auth/resend-code  { email, purpose? } */
const resendCode = asyncHandler(async (req, res) => {
  const v = new Validator();
  const email = v.email(req.body.email);
  const purpose = req.body.purpose === 'password_reset' ? 'password_reset' : 'email_verification';
  v.assert();

  const user = await findUserByEmail(email);
  if (user && (purpose === 'password_reset' || !user.email_verified)) {
    await issueCode(user, purpose);
  }
  res.json({ message: 'If the account exists, a new code has been sent.' });
});

/** POST /api/auth/login */
const login = asyncHandler(async (req, res) => {
  const v = new Validator();
  const email = v.email(req.body.email);
  const password = v.string(req.body.password, 'password', { max: 100 });
  v.assert();

  const user = await findUserByEmail(email);
  const ok = user && (await bcrypt.compare(password, user.password_hash));
  if (!ok) throw new HttpError(401, 'Incorrect email or password', 'INVALID_CREDENTIALS');

  if (!user.email_verified) {
    try {
      await issueCode(user, 'email_verification');
    } catch (_) {
      // cooldown active: previous code is still valid
    }
    throw new HttpError(403, 'Please verify your email to continue', 'EMAIL_NOT_VERIFIED');
  }

  res.json({ token: signToken(user.id), user: userToJson(user) });
});

/** POST /api/auth/forgot-password */
const forgotPassword = asyncHandler(async (req, res) => {
  const v = new Validator();
  const email = v.email(req.body.email);
  v.assert();

  const user = await findUserByEmail(email);
  let debugCode = null;
  if (user) {
    try {
      debugCode = await issueCode(user, 'password_reset');
    } catch (err) {
      if (err.status !== 429) throw err;
    }
  }
  // Same response whether or not the account exists (prevents user enumeration)
  res.json({
    message: 'If an account exists for this email, a reset code has been sent.',
    debug_code: debugCode,
  });
});

/** POST /api/auth/reset-password */
const resetPassword = asyncHandler(async (req, res) => {
  const v = new Validator();
  const email = v.email(req.body.email);
  const code = v.string(req.body.code, 'code', { min: 6, max: 6 });
  const newPassword = v.password(req.body.new_password, 'new_password');
  v.assert();

  const user = await findUserByEmail(email);
  if (!user) throw new HttpError(400, 'Incorrect code', 'CODE_INVALID');

  await consumeCode(user.id, 'password_reset', code);
  const hash = await bcrypt.hash(newPassword, 10);
  await pool.query('UPDATE users SET password_hash = ?, email_verified = 1 WHERE id = ?', [hash, user.id]);
  res.json({ message: 'Password updated successfully' });
});

module.exports = { register, verifyEmail, resendCode, login, forgotPassword, resetPassword };
