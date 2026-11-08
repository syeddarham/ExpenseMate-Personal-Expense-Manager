const { NotFoundError, ValidationError } = require('../utils/http');

/**
 * Add/edit/delete/list transactions. Owns the rules for resolving which
 * category and account a transaction belongs to, and keeps the receipt
 * (stored in its own table since migration 002) in step with the row.
 */
class TransactionService {
  constructor({ db, transactionRepository, receiptRepository, categoryRepository, accountRepository }) {
    this.db = db;
    this.transactions = transactionRepository;
    this.receipts = receiptRepository;
    this.categories = categoryRepository;
    this.accounts = accountRepository;
  }

  list(userId, filter) {
    return this.transactions.list(userId, filter);
  }

  async get(id, userId) {
    const row = await this.transactions.findById(id, userId);
    if (!row) throw new NotFoundError('Transaction not found');
    return row;
  }

  /**
   * @param {{ title: string, amount: number, type: 'income'|'expense', date: Date, note?: string|null,
   *           tags?: string|null, receiptUrl?: string|null, category?: unknown, account?: unknown }} input
   */
  async create(userId, input) {
    const data = await this.resolve(userId, input);
    const id = await this.db.transaction(async (tx) => {
      const newId = await this.transactions.withDb(tx).create(userId, data);
      if (data.receiptUrl) await this.receipts.withDb(tx).upsert(newId, data.receiptUrl);
      return newId;
    });
    return this.get(id, userId);
  }

  /** Full replacement (PUT semantics): omitting the receipt removes it. */
  async update(id, userId, input) {
    await this.get(id, userId);
    const data = await this.resolve(userId, input);
    await this.db.transaction(async (tx) => {
      await this.transactions.withDb(tx).update(id, userId, data);
      if (data.receiptUrl) await this.receipts.withDb(tx).upsert(id, data.receiptUrl);
      else await this.receipts.withDb(tx).delete(id);
    });
    return this.get(id, userId);
  }

  async delete(id, userId) {
    const deleted = await this.transactions.delete(id, userId); // receipt removed by ON DELETE CASCADE
    if (!deleted) throw new NotFoundError('Transaction not found');
  }

  async resolve(userId, input) {
    return {
      title: input.title,
      amount: input.amount,
      type: input.type,
      date: input.date,
      note: input.note || null,
      tags: input.tags || null,
      receiptUrl: input.receiptUrl || null,
      categoryId: await this.resolveCategoryId(userId, input.category, input.type),
      accountId: await this.resolveAccountId(userId, input.account),
    };
  }

  /**
   * The client may send a category id, a name, or nothing:
   *   1. a numeric id owned by the user
   *   2. a (partial) name match, preferring the transaction's kind
   *   3. otherwise the user's first category of that kind
   */
  async resolveCategoryId(userId, raw, type) {
    const isExpense = type === 'expense';
    if (isNumeric(raw)) {
      const owned = await this.categories.findOwned(Number(raw), userId);
      if (owned) return owned.id;
    }
    if (hasText(raw)) {
      const byName = await this.categories.findIdByNameLike(userId, String(raw), isExpense);
      if (byName) return byName;
    }
    const fallback = await this.categories.findFirstIdOfKind(userId, isExpense);
    if (fallback) return fallback;
    throw new ValidationError(`No matching category found for ${type}`);
  }

  /** Same idea as categories; a user with no accounts gets a "Cash" account created. */
  async resolveAccountId(userId, raw) {
    if (isNumeric(raw)) {
      const owned = await this.accounts.findIdOwnedBy(Number(raw), userId);
      if (owned) return owned;
    }
    if (hasText(raw)) {
      const byName = await this.accounts.findIdByName(userId, String(raw));
      if (byName) return byName;
    }
    const first = await this.accounts.findFirstId(userId);
    if (first) return first;
    return this.accounts.create(userId, { name: 'Cash', type: 'cash' });
  }
}

function isNumeric(raw) {
  return raw !== null && raw !== undefined && String(raw).trim() !== '' && !Number.isNaN(Number(raw));
}

function hasText(raw) {
  return raw !== null && raw !== undefined && String(raw).trim() !== '';
}

module.exports = { TransactionService };
