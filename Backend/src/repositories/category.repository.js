const { BaseRepository } = require('./base.repository');

class CategoryRepository extends BaseRepository {
  async countForUser(userId) {
    const rows = await this.db.query('SELECT COUNT(*) AS c FROM categories WHERE user_id = ?', [userId]);
    return Number(rows[0].c);
  }

  /** @param {{ isExpense?: boolean }} [filter] */
  async listForUser(userId, { isExpense } = {}) {
    if (isExpense === undefined) {
      return this.db.query('SELECT * FROM categories WHERE user_id = ? ORDER BY is_expense DESC, name ASC', [userId]);
    }
    return this.db.query('SELECT * FROM categories WHERE user_id = ? AND is_expense = ? ORDER BY is_expense DESC, name ASC', [
      userId,
      isExpense ? 1 : 0,
    ]);
  }

  async listExpenseCategories(userId) {
    return this.db.query('SELECT * FROM categories WHERE user_id = ? AND is_expense = 1 ORDER BY id', [userId]);
  }

  async findById(id) {
    const rows = await this.db.query('SELECT * FROM categories WHERE id = ?', [id]);
    return rows[0] || null;
  }

  async findOwned(id, userId) {
    const rows = await this.db.query('SELECT * FROM categories WHERE id = ? AND user_id = ?', [id, userId]);
    return rows[0] || null;
  }

  /** Case-insensitive name lookup, optionally ignoring one category id. */
  async findByName(userId, name, { excludeId = null } = {}) {
    const rows = await this.db.query(
      'SELECT * FROM categories WHERE user_id = ? AND LOWER(name) = LOWER(?) AND id <> ? LIMIT 1',
      [userId, name, excludeId || 0],
    );
    return rows[0] || null;
  }

  /** Exact or substring name match, preferring categories of the given kind. */
  async findIdByNameLike(userId, name, preferExpense) {
    const needle = name.trim().toLowerCase();
    const rows = await this.db.query(
      `SELECT id FROM categories
        WHERE user_id = ? AND (LOWER(name) = ? OR LOWER(name) LIKE ?)
        ORDER BY is_expense = ? DESC, LOWER(name) = ? DESC, id ASC
        LIMIT 1`,
      [userId, needle, `%${needle}%`, preferExpense ? 1 : 0, needle],
    );
    return rows.length > 0 ? rows[0].id : null;
  }

  async findFirstIdOfKind(userId, isExpense) {
    const rows = await this.db.query('SELECT id FROM categories WHERE user_id = ? AND is_expense = ? ORDER BY id ASC LIMIT 1', [
      userId,
      isExpense ? 1 : 0,
    ]);
    return rows.length > 0 ? rows[0].id : null;
  }

  /** @returns {Promise<number>} new category id */
  async create(userId, { name, icon, color, isExpense }) {
    const result = await this.db.query('INSERT INTO categories (user_id, name, icon, color, is_expense) VALUES (?, ?, ?, ?, ?)', [
      userId,
      name,
      icon,
      color,
      isExpense ? 1 : 0,
    ]);
    return result.insertId;
  }

  /** Inserts a default category, refreshing icon/colour if the name already exists. */
  async upsertDefault(userId, { name, icon, color, isExpense }) {
    await this.db.query(
      `INSERT INTO categories (user_id, name, icon, color, is_expense) VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE icon = VALUES(icon), color = VALUES(color)`,
      [userId, name, icon, color, isExpense ? 1 : 0],
    );
  }

  async update(id, userId, { name, icon, color, isExpense }) {
    await this.db.query('UPDATE categories SET name = ?, icon = ?, color = ?, is_expense = ? WHERE id = ? AND user_id = ?', [
      name,
      icon,
      color,
      isExpense ? 1 : 0,
      id,
      userId,
    ]);
  }

  async delete(id, userId) {
    await this.db.query('DELETE FROM categories WHERE id = ? AND user_id = ?', [id, userId]);
  }
}

module.exports = { CategoryRepository };
