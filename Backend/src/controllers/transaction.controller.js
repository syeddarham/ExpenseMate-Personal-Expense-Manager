const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { transactionToJson } = require('../utils/serializers');

const MAX_RECEIPT_CHARS = 10_000_000; // base64 images; DB column holds up to 16 MB

/**
 * HTTP layer for /api/transactions. Example trace for "Add Transaction":
 *   POST /api/transactions -> create() validates the body
 *   -> TransactionService.create() resolves category/account, opens a DB transaction
 *   -> TransactionRepository.create() + ReceiptRepository.upsert() run the SQL
 *   -> MySQL (transactions, transaction_receipts)
 */
function createTransactionController({ transactionService, exportService }) {
  return {
    list: asyncHandler(async (req, res) => {
      const filter = parseListQuery(req.query);
      const rows = await transactionService.list(req.user.id, filter);
      res.json({ transactions: rows.map(transactionToJson), limit: filter.limit, offset: filter.offset });
    }),

    get: asyncHandler(async (req, res) => {
      const id = parseId(req.params.id);
      res.json({ transaction: transactionToJson(await transactionService.get(id, req.user.id)) });
    }),

    create: asyncHandler(async (req, res) => {
      const input = parseTransactionBody(req.body);
      const row = await transactionService.create(req.user.id, input);
      res.status(201).json({ transaction: transactionToJson(row) });
    }),

    update: asyncHandler(async (req, res) => {
      const id = parseId(req.params.id);
      const input = parseTransactionBody(req.body);
      res.json({ transaction: transactionToJson(await transactionService.update(id, req.user.id, input)) });
    }),

    remove: asyncHandler(async (req, res) => {
      const id = parseId(req.params.id);
      await transactionService.delete(id, req.user.id);
      res.json({ message: 'Transaction deleted' });
    }),

    /** POST /api/transactions/export  { format: 'csv'|'pdf', send_email: boolean } */
    exportAll: asyncHandler(async (req, res) => {
      const format = (req.body.format || req.query.format || 'csv').toString();
      const result = await exportService.exportTransactions(req.user.id, {
        format,
        sendEmail: req.body.send_email !== false,
      });
      res.json({
        message: result.emailSent
          ? `Export successfully generated and sent to ${result.email}!`
          : `Export successfully generated (${result.filename})`,
        ...result,
      });
    }),
  };
}

function parseId(raw) {
  const v = new Validator();
  const id = v.id(raw, 'id');
  v.assert();
  return id;
}

/** Basic shape validation only; category/account resolution is a business rule (service). */
function parseTransactionBody(body) {
  const v = new Validator();
  const input = {
    title: v.string(body.title, 'title', { max: 160 }),
    amount: v.positiveNumber(body.amount, 'amount'),
    type: v.oneOf(body.type, 'type', ['income', 'expense']),
    date: body.date ? v.date(body.date, 'date') : new Date(),
    note: v.string(body.note, 'note', { required: false, max: 2000 }),
    tags: v.string(body.tags, 'tags', { required: false, max: 255 }),
    receiptUrl: v.string(body.receipt_url, 'receipt_url', { required: false, max: MAX_RECEIPT_CHARS }),
    category: body.category_id !== undefined ? body.category_id : body.category ? body.category.id || body.category.name : null,
    account: body.account_id !== undefined ? body.account_id : body.account || null,
  };
  v.assert();
  return input;
}

function parseListQuery(q) {
  const validDate = (s) => (s && !Number.isNaN(new Date(s).getTime()) ? new Date(s) : undefined);
  return {
    type: q.type === 'income' || q.type === 'expense' ? q.type : undefined,
    categoryId: q.category_id ? Number(q.category_id) : undefined,
    accountId: q.account_id ? Number(q.account_id) : undefined,
    from: validDate(q.from),
    to: validDate(q.to),
    search: q.search || undefined,
    limit: Math.min(Math.max(parseInt(q.limit || '200', 10) || 200, 1), 1000),
    offset: Math.max(parseInt(q.offset || '0', 10) || 0, 0),
  };
}

module.exports = { createTransactionController };
