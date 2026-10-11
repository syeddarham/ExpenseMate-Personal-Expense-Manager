const { pool } = require('../config/db');
const { HttpError } = require('../utils/http');
const { generateCode, hashCode } = require('../utils/otp');
const { sendCodeEmail } = require('./mailer');

const CODE_TTL_MINUTES = 10;
const RESEND_COOLDOWN_SECONDS = 30;
const MAX_ATTEMPTS = 5;

/**
 * Creates and e-mails a fresh one-time code. All time comparisons are done by
 * MySQL (NOW()) so they stay consistent regardless of server time zone.
 */
async function issueCode(user, purpose) {
  const [recent] = await pool.query(
    `SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS age
       FROM verification_codes
      WHERE user_id = ? AND purpose = ?
      ORDER BY id DESC LIMIT 1`,
    [user.id, purpose],
  );
  if (recent.length > 0 && recent[0].age < RESEND_COOLDOWN_SECONDS) {
    const wait = RESEND_COOLDOWN_SECONDS - recent[0].age;
    throw new HttpError(429, `Please wait ${wait}s before requesting another code`, 'TOO_MANY_REQUESTS');
  }

  const code = generateCode();
  await pool.query('UPDATE verification_codes SET consumed = 1 WHERE user_id = ? AND purpose = ?', [user.id, purpose]);
  await pool.query(
    `INSERT INTO verification_codes (user_id, purpose, code_hash, expires_at)
     VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ${CODE_TTL_MINUTES} MINUTE))`,
    [user.id, purpose, hashCode(code)],
  );
  await sendCodeEmail(user.email, purpose, code);
  return code;
}

/** Validates a submitted code and marks it consumed. Throws on failure. */
async function consumeCode(userId, purpose, code) {
  const [rows] = await pool.query(
    `SELECT id, code_hash, attempts, (expires_at > NOW()) AS valid
       FROM verification_codes
      WHERE user_id = ? AND purpose = ? AND consumed = 0
      ORDER BY id DESC LIMIT 1`,
    [userId, purpose],
  );
  if (rows.length === 0) throw new HttpError(400, 'No active code. Please request a new one.', 'CODE_INVALID');

  const row = rows[0];
  if (!row.valid) throw new HttpError(400, 'This code has expired. Please request a new one.', 'CODE_EXPIRED');
  if (row.attempts >= MAX_ATTEMPTS) {
    throw new HttpError(429, 'Too many incorrect attempts. Please request a new code.', 'CODE_LOCKED');
  }

  if (row.code_hash !== hashCode(code)) {
    await pool.query('UPDATE verification_codes SET attempts = attempts + 1 WHERE id = ?', [row.id]);
    throw new HttpError(400, 'Incorrect code', 'CODE_INVALID');
  }
  await pool.query('UPDATE verification_codes SET consumed = 1 WHERE id = ?', [row.id]);
}

module.exports = { issueCode, consumeCode };
