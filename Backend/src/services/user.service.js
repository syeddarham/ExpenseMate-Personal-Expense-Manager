const bcrypt = require('bcryptjs');
const { ConflictError, NotFoundError, ValidationError } = require('../utils/http');
const { BCRYPT_ROUNDS } = require('./auth.service');

class UserService {
  constructor({ db, userRepository, accountRepository, transactionRepository, budgetRepository }) {
    this.db = db;
    this.users = userRepository;
    this.accounts = accountRepository;
    this.transactions = transactionRepository;
    this.budgets = budgetRepository;
  }

  async getProfile(userId) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundError('User not found');
    return user;
  }

  /**
   * Applies any subset of profile/preference changes.
   * @param {{ fullName?: string, email?: string, avatarUrl?: string|null, primaryColor?: string,
   *           country?: string, currencyCode?: string, currencySymbol?: string,
   *           darkMode?: boolean, biometricEnabled?: boolean }} changes
   */
  async updateProfile(userId, changes) {
    if (changes.email !== undefined && (await this.users.isEmailTakenByOther(changes.email, userId))) {
      throw new ConflictError('This email address is already in use by another account', 'EMAIL_TAKEN');
    }
    const columns = {};
    const map = {
      fullName: 'full_name',
      email: 'email',
      avatarUrl: 'avatar_url',
      primaryColor: 'primary_color',
      country: 'country',
      currencyCode: 'currency_code',
      currencySymbol: 'currency_symbol',
    };
    for (const [key, column] of Object.entries(map)) {
      if (changes[key] !== undefined) columns[column] = changes[key];
    }
    if (changes.darkMode !== undefined) columns.dark_mode = changes.darkMode ? 1 : 0;
    if (changes.biometricEnabled !== undefined) columns.biometric_enabled = changes.biometricEnabled ? 1 : 0;

    await this.users.updateProfile(userId, columns);
    return this.getProfile(userId);
  }

  async changePassword(userId, currentPassword, newPassword) {
    const user = await this.getProfile(userId);
    if (!(await bcrypt.compare(currentPassword, user.password_hash))) {
      throw new ValidationError('Current password is incorrect', 'INVALID_CREDENTIALS');
    }
    await this.users.updatePasswordHash(userId, await bcrypt.hash(newPassword, BCRYPT_ROUNDS));
  }

  /**
   * Switches the display currency. When `convertAmounts` is set and the
   * currency actually changes, every stored amount is multiplied by `rate`
   * in one database transaction so balances stay consistent.
   */
  async changeCurrency(userId, { currencyCode, currencySymbol, convertAmounts, rate }) {
    const user = await this.getProfile(userId);
    const sameCurrency = (user.currency_code || 'USD').toUpperCase() === currencyCode;
    const shouldConvert = convertAmounts && !sameCurrency && rate !== 1;

    await this.db.transaction(async (tx) => {
      if (shouldConvert) {
        await this.accounts.withDb(tx).scaleOpeningBalances(userId, rate);
        await this.transactions.withDb(tx).scaleAmounts(userId, rate);
        await this.budgets.withDb(tx).scaleLimits(userId, rate);
      }
      await this.users.withDb(tx).updateCurrency(userId, currencyCode, currencySymbol);
    });
    return this.getProfile(userId);
  }
}

module.exports = { UserService };
