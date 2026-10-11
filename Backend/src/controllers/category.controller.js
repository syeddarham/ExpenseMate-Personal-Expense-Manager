const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { categoryToJson } = require('../utils/serializers');

const COLOR_RE = /^#[0-9a-fA-F]{6}$/;

const DEFAULT_CATEGORIES = [
  { name: 'Food & Dining', icon: 'restaurant', color: '#F59E0B', is_expense: 1 },
  { name: 'Groceries', icon: 'shopping_cart', color: '#10B981', is_expense: 1 },
  { name: 'Transport', icon: 'directions_car', color: '#3B82F6', is_expense: 1 },
  { name: 'Bills & Utilities', icon: 'receipt_long', color: '#8B5CF6', is_expense: 1 },
  { name: 'Entertainment', icon: 'movie', color: '#EC4899', is_expense: 1 },
  { name: 'Health', icon: 'medical_services', color: '#EF4444', is_expense: 1 },
  { name: 'Shopping', icon: 'shopping_bag', color: '#F97316', is_expense: 1 },
  { name: 'Education', icon: 'school', color: '#0EA5E9', is_expense: 1 },
  { name: 'Travel', icon: 'flight', color: '#14B8A6', is_expense: 1 },
  { name: 'Salary / Income', icon: 'attach_money', color: '#059669', is_expense: 0 },
  { name: 'Freelance', icon: 'work', color: '#6366F1', is_expense: 0 },
  { name: 'Investments', icon: 'trending_up', color: '#06B6D4', is_expense: 0 },
  { name: 'Gifts', icon: 'card_giftcard', color: '#D946EF', is_expense: 0 },
];

async function seedDefaultCategoriesForUser(userId, conn = pool) {
  for (const cat of DEFAULT_CATEGORIES) {
    await conn.query(
      `INSERT INTO categories (user_id, name, icon, color, is_expense)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE icon = VALUES(icon), color = VALUES(color)`,
      [userId, cat.name, cat.icon, cat.color, cat.is_expense]
    );
  }
}

/** GET /api/categories?type=expense|income */
const listCategories = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  // Auto-seed default categories if user has none
  const [countRows] = await pool.query('SELECT COUNT(*) AS count FROM categories WHERE user_id = ?', [userId]);
  if (countRows[0].count === 0) {
    await seedDefaultCategoriesForUser(userId);
  }

  const params = [userId];
  let filter = '';
  if (req.query.type === 'expense' || req.query.type === 'income') {
    filter = 'AND is_expense = ?';
    params.push(req.query.type === 'expense' ? 1 : 0);
  }
  const [rows] = await pool.query(
    `SELECT * FROM categories WHERE user_id = ? ${filter} ORDER BY is_expense DESC, name ASC`,
    params,
  );
  res.json({ categories: rows.map(categoryToJson) });
});

/** POST /api/categories */
const createCategory = asyncHandler(async (req, res) => {
  const v = new Validator();
  const name = v.string(req.body.name, 'name', { min: 1, max: 80 });
  const icon = v.string(req.body.icon || 'category', 'icon', { max: 50 });
  const color = req.body.color || '#10B981';
  if (!COLOR_RE.test(color)) v.fail('color', 'color must be a hex value like #10B981');
  const isExpense = req.body.is_expense === undefined ? true : !!req.body.is_expense;
  v.assert();

  // Check duplicate
  const [existing] = await pool.query(
    'SELECT id FROM categories WHERE user_id = ? AND LOWER(name) = LOWER(?)',
    [req.user.id, name]
  );
  if (existing.length > 0) {
    throw new HttpError(400, `A category named "${name}" already exists`, 'DUPLICATE_CATEGORY');
  }

  const [result] = await pool.query(
    'INSERT INTO categories (user_id, name, icon, color, is_expense) VALUES (?, ?, ?, ?, ?)',
    [req.user.id, name, icon, color, isExpense ? 1 : 0],
  );
  const [rows] = await pool.query('SELECT * FROM categories WHERE id = ?', [result.insertId]);
  res.status(201).json({ category: categoryToJson(rows[0]) });
});

/** PUT /api/categories/:id */
const updateCategory = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  const name = v.string(req.body.name, 'name', { min: 1, max: 80 });
  const icon = v.string(req.body.icon || 'category', 'icon', { max: 50 });
  const color = req.body.color || '#10B981';
  if (!COLOR_RE.test(color)) v.fail('color', 'color must be a hex value like #10B981');
  const isExpense = req.body.is_expense === undefined ? true : !!req.body.is_expense;
  v.assert();

  // Check category exists and belongs to user
  const [existing] = await pool.query('SELECT * FROM categories WHERE id = ? AND user_id = ?', [id, req.user.id]);
  if (existing.length === 0) {
    throw new HttpError(404, 'Category not found', 'NOT_FOUND');
  }

  // Check duplicate name
  const [dup] = await pool.query(
    'SELECT id FROM categories WHERE user_id = ? AND LOWER(name) = LOWER(?) AND id <> ?',
    [req.user.id, name, id]
  );
  if (dup.length > 0) {
    throw new HttpError(400, `A category named "${name}" already exists`, 'DUPLICATE_CATEGORY');
  }

  await pool.query(
    'UPDATE categories SET name = ?, icon = ?, color = ?, is_expense = ? WHERE id = ? AND user_id = ?',
    [name, icon, color, isExpense ? 1 : 0, id, req.user.id]
  );

  const [rows] = await pool.query('SELECT * FROM categories WHERE id = ?', [id]);
  res.json({ category: categoryToJson(rows[0]) });
});

/** DELETE /api/categories/:id */
const deleteCategory = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  v.assert();

  const [existing] = await pool.query('SELECT * FROM categories WHERE id = ? AND user_id = ?', [id, req.user.id]);
  if (existing.length === 0) {
    throw new HttpError(404, 'Category not found', 'NOT_FOUND');
  }

  // Check if any transactions reference this category
  const [txs] = await pool.query(
    'SELECT COUNT(*) AS count FROM transactions WHERE category_id = ? AND user_id = ?',
    [id, req.user.id]
  );
  if (txs[0].count > 0) {
    throw new HttpError(
      400,
      `Cannot delete "${existing[0].name}" because it is linked to ${txs[0].count} transaction(s). Please reassign or delete those transactions first.`,
      'CATEGORY_IN_USE'
    );
  }

  await pool.query('DELETE FROM categories WHERE id = ? AND user_id = ?', [id, req.user.id]);
  res.json({ message: 'Category deleted successfully' });
});

module.exports = {
  DEFAULT_CATEGORIES,
  seedDefaultCategoriesForUser,
  listCategories,
  createCategory,
  updateCategory,
  deleteCategory,
};
