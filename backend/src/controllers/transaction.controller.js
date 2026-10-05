const { pool } = require('../config/db');
const { HttpError, asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { TRANSACTION_SELECT, transactionToJson } = require('../utils/serializers');

async function loadTransaction(id, userId) {
  const [rows] = await pool.query(`${TRANSACTION_SELECT} WHERE t.id = ? AND t.user_id = ?`, [id, userId]);
  if (rows.length === 0) throw new HttpError(404, 'Transaction not found', 'NOT_FOUND');
  return rows[0];
}

/** Validates the body and verifies ownership of the referenced account/category. */
async function parseTransactionBody(body, userId) {
  const v = new Validator();
  const title = v.string(body.title, 'title', { max: 160 });
  const amount = v.positiveNumber(body.amount, 'amount');
  const type = v.oneOf(body.type, 'type', ['income', 'expense']);
  const isExpense = type === 'expense' ? 1 : 0;
  const date = body.date ? v.date(body.date, 'date') : new Date();
  const note = v.string(body.note, 'note', { required: false, max: 2000 });
  const tags = v.string(body.tags, 'tags', { required: false, max: 255 });
  const receiptUrl = v.string(body.receipt_url, 'receipt_url', { required: false, max: 500 });
  v.assert();

  // Resolve category (can be id or name or slug)
  let categoryId = null;
  const rawCat = body.category_id !== undefined ? body.category_id : (body.category ? (body.category.id || body.category.name) : null);
  if (rawCat !== null && !isNaN(Number(rawCat))) {
    const [cats] = await pool.query(
      'SELECT id, is_expense FROM categories WHERE id = ? AND user_id = ?',
      [Number(rawCat), userId],
    );
    if (cats.length > 0) {
      categoryId = cats[0].id;
    }
  }

  if (!categoryId && rawCat) {
    const catStr = String(rawCat).trim().toLowerCase();
    const [cats] = await pool.query(
      'SELECT id, is_expense FROM categories WHERE user_id = ? AND (LOWER(name) = ? OR LOWER(name) LIKE ?) ORDER BY is_expense = ? DESC LIMIT 1',
      [userId, catStr, `%${catStr}%`, isExpense],
    );
    if (cats.length > 0) {
      categoryId = cats[0].id;
    }
  }

  if (!categoryId) {
    const [cats] = await pool.query(
      'SELECT id FROM categories WHERE is_expense = ? AND user_id = ? ORDER BY id ASC LIMIT 1',
      [isExpense, userId],
    );
    if (cats.length > 0) {
      categoryId = cats[0].id;
    } else {
      throw new HttpError(400, `No matching category found for ${type}`, 'VALIDATION_ERROR');
    }
  }

  // Resolve account (can be numeric id or name like 'Cash' or default)
  let accountId = null;
  const rawAcc = body.account_id !== undefined ? body.account_id : (body.account || null);
  if (rawAcc !== null && !isNaN(Number(rawAcc))) {
    const [accs] = await pool.query('SELECT id FROM accounts WHERE id = ? AND user_id = ?', [Number(rawAcc), userId]);
    if (accs.length > 0) {
      accountId = accs[0].id;
    }
  }

  if (!accountId && rawAcc) {
    const accStr = String(rawAcc).trim().toLowerCase();
    const [accs] = await pool.query(
      'SELECT id FROM accounts WHERE user_id = ? AND (LOWER(name) = ? OR LOWER(name) LIKE ?) LIMIT 1',
      [userId, accStr, `%${accStr}%`],
    );
    if (accs.length > 0) {
      accountId = accs[0].id;
    }
  }

  if (!accountId) {
    const [accs] = await pool.query('SELECT id FROM accounts WHERE user_id = ? ORDER BY id ASC LIMIT 1', [userId]);
    if (accs.length > 0) {
      accountId = accs[0].id;
    } else {
      // Create a default account if user has none
      const [newAcc] = await pool.query('INSERT INTO accounts (user_id, name, type) VALUES (?, ?, ?)', [userId, 'Cash', 'cash']);
      accountId = newAcc.insertId;
    }
  }

  return { title, amount, type, categoryId, accountId, date, note: note || null, tags: tags || null, receiptUrl: receiptUrl || null };
}

/** GET /api/transactions */
const listTransactions = asyncHandler(async (req, res) => {
  const q = req.query;
  const where = ['t.user_id = ?'];
  const params = [req.user.id];

  if (q.type === 'income' || q.type === 'expense') {
    where.push('t.type = ?');
    params.push(q.type);
  }
  if (q.category_id) {
    where.push('t.category_id = ?');
    params.push(Number(q.category_id));
  }
  if (q.account_id) {
    where.push('t.account_id = ?');
    params.push(Number(q.account_id));
  }
  if (q.from && !Number.isNaN(new Date(q.from).getTime())) {
    where.push('t.transaction_date >= ?');
    params.push(new Date(q.from));
  }
  if (q.to && !Number.isNaN(new Date(q.to).getTime())) {
    where.push('t.transaction_date < ?');
    params.push(new Date(q.to));
  }
  if (q.search) {
    where.push('(t.title LIKE ? OR t.note LIKE ?)');
    params.push(`%${q.search}%`, `%${q.search}%`);
  }

  const limit = Math.min(Math.max(parseInt(q.limit || '200', 10) || 200, 1), 1000);
  const offset = Math.max(parseInt(q.offset || '0', 10) || 0, 0);

  const [rows] = await pool.query(
    `${TRANSACTION_SELECT} WHERE ${where.join(' AND ')} ORDER BY t.transaction_date DESC, t.id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );
  res.json({ transactions: rows.map(transactionToJson), limit, offset });
});

/** GET /api/transactions/:id */
const getTransaction = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  v.assert();
  res.json({ transaction: transactionToJson(await loadTransaction(id, req.user.id)) });
});

/** POST /api/transactions */
const createTransaction = asyncHandler(async (req, res) => {
  const t = await parseTransactionBody(req.body, req.user.id);
  const [result] = await pool.query(
    `INSERT INTO transactions
       (user_id, account_id, category_id, title, amount, type, note, tags, receipt_url, transaction_date)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [req.user.id, t.accountId, t.categoryId, t.title, t.amount, t.type, t.note, t.tags, t.receiptUrl, t.date],
  );
  res.status(201).json({ transaction: transactionToJson(await loadTransaction(result.insertId, req.user.id)) });
});

/** PUT /api/transactions/:id */
const updateTransaction = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  v.assert();
  await loadTransaction(id, req.user.id);

  const t = await parseTransactionBody(req.body, req.user.id);
  await pool.query(
    `UPDATE transactions
        SET account_id = ?, category_id = ?, title = ?, amount = ?, type = ?,
            note = ?, tags = ?, receipt_url = ?, transaction_date = ?
      WHERE id = ? AND user_id = ?`,
    [t.accountId, t.categoryId, t.title, t.amount, t.type, t.note, t.tags, t.receiptUrl, t.date, id, req.user.id],
  );
  res.json({ transaction: transactionToJson(await loadTransaction(id, req.user.id)) });
});

/** DELETE /api/transactions/:id */
const deleteTransaction = asyncHandler(async (req, res) => {
  const v = new Validator();
  const id = v.id(req.params.id, 'id');
  v.assert();

  const [result] = await pool.query('DELETE FROM transactions WHERE id = ? AND user_id = ?', [id, req.user.id]);
  if (result.affectedRows === 0) throw new HttpError(404, 'Transaction not found', 'NOT_FOUND');
  res.json({ message: 'Transaction deleted' });
});

/** POST /api/transactions/export  { format: 'csv'|'pdf', send_email: boolean } */
const exportTransactions = asyncHandler(async (req, res) => {
  const { exportUserTransactions } = require('../services/export.service');
  const format = (req.body.format || req.query.format || 'csv').toString().toLowerCase();
  const sendEmail = req.body.send_email !== false;

  const result = await exportUserTransactions(req.user.id, {
    format,
    sendEmail,
  });

  res.json({
    message: result.emailSent
      ? `Export successfully generated and sent to ${result.email}!`
      : `Export successfully generated (${result.filename})`,
    ...result,
  });
});

module.exports = {
  listTransactions,
  getTransaction,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  exportTransactions,
};

