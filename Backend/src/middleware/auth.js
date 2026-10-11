const jwt = require('jsonwebtoken');
const env = require('../config/env');
const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');

/** Requires a valid Bearer token and attaches the user row to req.user. */
const requireAuth = asyncHandler(async (req, _res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new HttpError(401, 'Authentication required', 'UNAUTHENTICATED');

  let payload;
  try {
    payload = jwt.verify(token, env.jwt.secret);
  } catch (_) {
    throw new HttpError(401, 'Invalid or expired token', 'INVALID_TOKEN');
  }

  const [rows] = await pool.query('SELECT id, email, email_verified FROM users WHERE id = ?', [payload.sub]);
  if (rows.length === 0) throw new HttpError(401, 'Account no longer exists', 'INVALID_TOKEN');
  req.user = rows[0];
  next();
});

function signToken(userId) {
  return jwt.sign({ sub: userId }, env.jwt.secret, { expiresIn: env.jwt.expiresIn });
}

module.exports = { requireAuth, signToken };
