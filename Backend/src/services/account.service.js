const { NotFoundError } = require('../utils/http');

const ACCOUNT_TYPES = ['cash', 'bank', 'card', 'wallet'];

const DEFAULT_ACCOUNTS = [
  { name: 'Cash', type: 'cash' },
  { name: 'Bank Account', type: 'bank' },
  { name: 'Debit Card', type: 'card' },
  { name: 'Credit Card', type: 'card' },
  { name: 'Digital Wallet', type: 'wallet' },
];

/** Business rule: balance = opening balance + income - expense. */
function accountBalance({ opening_balance, income_total = 0, expense_total = 0 }) {
  return round2(Number(opening_balance) + Number(income_total) - Number(expense_total));
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

class AccountService {
  constructor({ accountRepository }) {
    this.accounts = accountRepository;
  }

  async list(userId) {
    const rows = await this.accounts.listWithTotals(userId);
    return rows.map(withBalance);
  }

  async get(id, userId) {
    const row = await this.accounts.findWithTotals(id, userId);
    if (!row) throw new NotFoundError('Account not found');
    return withBalance(row);
  }

  async create(userId, { name, type = 'cash', openingBalance = 0 }) {
    const id = await this.accounts.create(userId, { name, type, openingBalance });
    return this.get(id, userId);
  }

  /** @param {{ name?: string, type?: string, openingBalance?: number }} changes */
  async update(id, userId, changes) {
    await this.get(id, userId); // 404 if missing or not owned
    const columns = {};
    if (changes.name !== undefined) columns.name = changes.name;
    if (changes.type !== undefined) columns.type = changes.type;
    if (changes.openingBalance !== undefined) columns.opening_balance = changes.openingBalance;
    await this.accounts.update(id, userId, columns);
    return this.get(id, userId);
  }

  async delete(id, userId) {
    const deleted = await this.accounts.delete(id, userId);
    if (!deleted) throw new NotFoundError('Account not found');
  }

  /** Inserts the five starter accounts. `db` lets registration run this inside its transaction. */
  async createDefaultAccounts(userId, db = null) {
    const repo = db ? this.accounts.withDb(db) : this.accounts;
    for (const account of DEFAULT_ACCOUNTS) {
      await repo.create(userId, account);
    }
  }

  /** Recreates the starter accounts for a user who has none (e.g. after deleting them all). */
  async ensureDefaultAccounts(userId) {
    if ((await this.accounts.countForUser(userId)) === 0) {
      await this.createDefaultAccounts(userId);
    }
  }
}

function withBalance(row) {
  return { ...row, balance: accountBalance(row) };
}

module.exports = { AccountService, ACCOUNT_TYPES, DEFAULT_ACCOUNTS, accountBalance };
