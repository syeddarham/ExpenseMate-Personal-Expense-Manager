const { generateCode, hashCode } = require('../utils/otp');
const { ValidationError, TooManyRequestsError } = require('../utils/http');

const PURPOSES = ['email_verification', 'password_reset'];

/**
 * One-time e-mail codes: issuing (with resend cooldown) and checking (with
 * expiry and attempt limits). Only a SHA-256 hash of each code is stored.
 */
class VerificationCodeService {
  constructor({ codeRepository, mailer, ttlMinutes = 10, resendCooldownSeconds = 30, maxAttempts = 5 }) {
    this.codes = codeRepository;
    this.mailer = mailer;
    this.ttlMinutes = ttlMinutes;
    this.resendCooldownSeconds = resendCooldownSeconds;
    this.maxAttempts = maxAttempts;
  }

  /** Creates and e-mails a fresh code. Throws TooManyRequestsError during the cooldown. */
  async issue(user, purpose) {
    assertPurpose(purpose);
    const age = await this.codes.secondsSinceLatest(user.id, purpose);
    if (age !== null && age < this.resendCooldownSeconds) {
      throw new TooManyRequestsError(`Please wait ${this.resendCooldownSeconds - age}s before requesting another code`);
    }

    const code = generateCode();
    await this.codes.invalidateAll(user.id, purpose);
    await this.codes.create(user.id, purpose, hashCode(code), this.ttlMinutes);
    await this.mailer.sendCodeEmail(user.email, purpose, code);
    return code;
  }

  /** Issues a code but treats an active cooldown as success (the previous code is still valid). */
  async issueIgnoringCooldown(user, purpose) {
    try {
      await this.issue(user, purpose);
    } catch (err) {
      if (!(err instanceof TooManyRequestsError)) throw err;
    }
  }

  /** Validates a submitted code and marks it consumed. Throws on any failure. */
  async consume(userId, purpose, code) {
    assertPurpose(purpose);
    const active = await this.codes.findLatestActive(userId, purpose);
    if (!active) throw new ValidationError('No active code. Please request a new one.', 'CODE_INVALID');
    if (active.expired) throw new ValidationError('This code has expired. Please request a new one.', 'CODE_EXPIRED');
    if (active.attempts >= this.maxAttempts) {
      throw new TooManyRequestsError('Too many incorrect attempts. Please request a new code.', 'CODE_LOCKED');
    }
    if (active.codeHash !== hashCode(code)) {
      await this.codes.incrementAttempts(active.id);
      throw new ValidationError('Incorrect code', 'CODE_INVALID');
    }
    await this.codes.markConsumed(active.id);
  }
}

function assertPurpose(purpose) {
  if (!PURPOSES.includes(purpose)) throw new Error(`Unknown code purpose: ${purpose}`);
}

module.exports = { VerificationCodeService };
