const { BaseRepository } = require('./base.repository');

/** Columns a profile update may change (guards the dynamic UPDATE below). */
const UPDATABLE_COLUMNS = new Set([
  'full_name',
  'email',
  'avatar_url',
  'primary_color',
  'country',
  'currency_code',
  'currency_symbol',
  'dark_mode',
  'biometric_enabled',
]);

class UserRepository extends BaseRepository {
  async findById(id) {
    const rows = await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
    return rows[0] || null;
  }

  async findByEmail(email) {
    const rows = await this.db.query('SELECT * FROM users WHERE email = ?', [email]);
    return rows[0] || null;
  }

  async isEmailTakenByOther(email, excludeUserId) {
    const rows = await this.db.query('SELECT id FROM users WHERE email = ? AND id <> ?', [email, excludeUserId]);
    return rows.length > 0;
  }

  /** @returns {Promise<number>} new user id */
  async create({ fullName, email, passwordHash, currencyCode, currencySymbol, country }) {
    const result = await this.db.query(
      `INSERT INTO users (full_name, email, password_hash, currency_code, currency_symbol, country)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [fullName, email, passwordHash, currencyCode, currencySymbol, country],
    );
    return result.insertId;
  }

  /** Refreshes the details of an unverified account that registers again. */
  async updateRegistration(id, { fullName, passwordHash, currencyCode, currencySymbol, country }) {
    await this.db.query(
      `UPDATE users
          SET full_name = ?, password_hash = ?, currency_code = ?, currency_symbol = ?,
              country = COALESCE(?, country)
        WHERE id = ?`,
      [fullName, passwordHash, currencyCode, currencySymbol, country, id],
    );
  }

  async markEmailVerified(id) {
    await this.db.query('UPDATE users SET email_verified = 1 WHERE id = ?', [id]);
  }

  async updatePasswordHash(id, passwordHash, { markVerified = false } = {}) {
    const sql = markVerified
      ? 'UPDATE users SET password_hash = ?, email_verified = 1 WHERE id = ?'
      : 'UPDATE users SET password_hash = ? WHERE id = ?';
    await this.db.query(sql, [passwordHash, id]);
  }

  /** @param {Record<string, unknown>} changes column -> value (whitelisted) */
  async updateProfile(id, changes) {
    const columns = Object.keys(changes);
    if (columns.length === 0) return;
    for (const column of columns) {
      if (!UPDATABLE_COLUMNS.has(column)) throw new Error(`Column ${column} cannot be updated`);
    }
    const assignments = columns.map((c) => `${c} = ?`).join(', ');
    await this.db.query(`UPDATE users SET ${assignments} WHERE id = ?`, [...columns.map((c) => changes[c]), id]);
  }

  async updateCurrency(id, currencyCode, currencySymbol) {
    await this.db.query('UPDATE users SET currency_code = ?, currency_symbol = ? WHERE id = ?', [
      currencyCode,
      currencySymbol,
      id,
    ]);
  }
}

module.exports = { UserRepository };
