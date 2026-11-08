const { BaseRepository } = require('./base.repository');

/**
 * One-time codes. All time arithmetic uses MySQL NOW() so results do not
 * depend on the API server's clock or time zone.
 */
class VerificationCodeRepository extends BaseRepository {
  /** Seconds since the latest code for this user/purpose was issued, or null. */
  async secondsSinceLatest(userId, purpose) {
    const rows = await this.db.query(
      `SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS age
         FROM verification_codes
        WHERE user_id = ? AND purpose = ?
        ORDER BY id DESC LIMIT 1`,
      [userId, purpose],
    );
    return rows.length > 0 ? Number(rows[0].age) : null;
  }

  async invalidateAll(userId, purpose) {
    await this.db.query('UPDATE verification_codes SET consumed = 1 WHERE user_id = ? AND purpose = ?', [userId, purpose]);
  }

  async create(userId, purpose, codeHash, ttlMinutes) {
    await this.db.query(
      `INSERT INTO verification_codes (user_id, purpose, code_hash, expires_at)
       VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))`,
      [userId, purpose, codeHash, ttlMinutes],
    );
  }

  /** Latest unconsumed code with an `expired` flag, or null. */
  async findLatestActive(userId, purpose) {
    const rows = await this.db.query(
      `SELECT id, code_hash, attempts, (expires_at <= NOW()) AS expired
         FROM verification_codes
        WHERE user_id = ? AND purpose = ? AND consumed = 0
        ORDER BY id DESC LIMIT 1`,
      [userId, purpose],
    );
    if (rows.length === 0) return null;
    const row = rows[0];
    return { id: row.id, codeHash: row.code_hash, attempts: Number(row.attempts), expired: !!row.expired };
  }

  async incrementAttempts(id) {
    await this.db.query('UPDATE verification_codes SET attempts = attempts + 1 WHERE id = ?', [id]);
  }

  async markConsumed(id) {
    await this.db.query('UPDATE verification_codes SET consumed = 1 WHERE id = ?', [id]);
  }
}

module.exports = { VerificationCodeRepository };
