const bcrypt = require('bcryptjs');
const { ConflictError, ForbiddenError, NotFoundError, UnauthorizedError, ValidationError } = require('../utils/http');

const BCRYPT_ROUNDS = 10;

/** Registration, e-mail verification, login and password reset. */
class AuthService {
  constructor({ db, userRepository, accountService, categoryService, codeService, tokenService }) {
    this.db = db;
    this.users = userRepository;
    this.accounts = accountService;
    this.categories = categoryService;
    this.codes = codeService;
    this.tokens = tokenService;
  }

  /**
   * Creates an account (with default accounts and categories) and e-mails a
   * verification code. An unverified e-mail may register again; its details
   * are refreshed.
   */
  async register({ fullName, email, password, currencyCode = 'USD', currencySymbol = '$', country = null }) {
    const details = {
      fullName,
      passwordHash: await bcrypt.hash(password, BCRYPT_ROUNDS),
      currencyCode: String(currencyCode).toUpperCase().slice(0, 10),
      currencySymbol: String(currencySymbol).slice(0, 10),
      country: country ? String(country).slice(0, 80) : null,
    };

    const existing = await this.users.findByEmail(email);
    if (existing && existing.email_verified) {
      throw new ConflictError('An account with this email already exists', 'EMAIL_TAKEN');
    }

    let user = existing;
    if (existing) {
      await this.users.updateRegistration(existing.id, details);
    } else {
      const userId = await this.db.transaction(async (tx) => {
        const id = await this.users.withDb(tx).create({ ...details, email });
        await this.accounts.createDefaultAccounts(id, tx);
        await this.categories.seedDefaults(id, tx);
        return id;
      });
      user = { id: userId, email };
    }

    await this.codes.issue(user, 'email_verification');
    return { email };
  }

  async verifyEmail(email, code) {
    const user = await this.users.findByEmail(email);
    if (!user) throw new NotFoundError('Account not found');
    await this.codes.consume(user.id, 'email_verification', code);
    await this.users.markEmailVerified(user.id);
    return { token: this.tokens.sign(user.id), user: { ...user, email_verified: 1 } };
  }

  /** Always succeeds silently so the endpoint cannot be used to discover accounts. */
  async resendCode(email, purpose) {
    const user = await this.users.findByEmail(email);
    if (user && (purpose === 'password_reset' || !user.email_verified)) {
      await this.codes.issue(user, purpose);
    }
  }

  async login(email, password) {
    const user = await this.users.findByEmail(email);
    const ok = user && (await bcrypt.compare(password, user.password_hash));
    if (!ok) throw new UnauthorizedError('Incorrect email or password', 'INVALID_CREDENTIALS');

    if (!user.email_verified) {
      // Best effort: the client must still receive EMAIL_NOT_VERIFIED so it can
      // open the verification screen, even if the e-mail could not be sent.
      try {
        await this.codes.issue(user, 'email_verification');
      } catch (_) {
        /* cooldown active or mail failure: previous code is still valid */
      }
      throw new ForbiddenError('Please verify your email to continue', 'EMAIL_NOT_VERIFIED');
    }

    await this.accounts.ensureDefaultAccounts(user.id);
    return { token: this.tokens.sign(user.id), user };
  }

  /** Same outcome whether or not the account exists (prevents user enumeration). */
  async forgotPassword(email) {
    const user = await this.users.findByEmail(email);
    if (user) await this.codes.issueIgnoringCooldown(user, 'password_reset');
  }

  async resetPassword(email, code, newPassword) {
    const user = await this.users.findByEmail(email);
    if (!user) throw new ValidationError('Incorrect code', 'CODE_INVALID');
    await this.codes.consume(user.id, 'password_reset', code);
    await this.users.updatePasswordHash(user.id, await bcrypt.hash(newPassword, BCRYPT_ROUNDS), { markVerified: true });
  }

  /** Resolves a bearer token to its user, or throws UnauthorizedError. */
  async authenticate(token) {
    if (!token) throw new UnauthorizedError('Authentication required', 'UNAUTHENTICATED');
    const userId = this.tokens.verify(token);
    if (!userId) throw new UnauthorizedError('Invalid or expired token', 'INVALID_TOKEN');
    const user = await this.users.findById(userId);
    if (!user) throw new UnauthorizedError('Account no longer exists', 'INVALID_TOKEN');
    return { id: user.id, email: user.email, email_verified: user.email_verified };
  }
}

module.exports = { AuthService, BCRYPT_ROUNDS };
