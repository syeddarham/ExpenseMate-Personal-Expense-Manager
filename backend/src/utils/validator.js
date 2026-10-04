const { HttpError } = require('./http');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Collects validation problems and throws a single 400 error. */
class Validator {
  constructor() {
    this.errors = [];
  }

  fail(field, message) {
    this.errors.push({ field, message });
  }

  string(value, field, { min = 1, max = 255, required = true } = {}) {
    if (value === undefined || value === null || value === '') {
      if (required) this.fail(field, `${field} is required`);
      return undefined;
    }
    if (typeof value !== 'string') {
      this.fail(field, `${field} must be a string`);
      return undefined;
    }
    const trimmed = value.trim();
    if (trimmed.length < min || trimmed.length > max) {
      this.fail(field, `${field} must be between ${min} and ${max} characters`);
    }
    return trimmed;
  }

  email(value, field = 'email') {
    const v = this.string(value, field, { max: 190 });
    if (v && !EMAIL_RE.test(v)) this.fail(field, 'Enter a valid email address');
    return v ? v.toLowerCase() : v;
  }

  password(value, field = 'password') {
    if (typeof value !== 'string' || value.length < 8 || value.length > 100) {
      this.fail(field, 'Password must be 8-100 characters');
    }
    return value;
  }

  positiveNumber(value, field) {
    const n = Number(value);
    if (!Number.isFinite(n) || n <= 0 || n > 999999999999) this.fail(field, `${field} must be a positive number`);
    return n;
  }

  nonNegativeNumber(value, field) {
    const n = Number(value);
    if (!Number.isFinite(n) || n < 0 || n > 999999999999) this.fail(field, `${field} must be zero or greater`);
    return n;
  }

  oneOf(value, field, options) {
    if (!options.includes(value)) this.fail(field, `${field} must be one of: ${options.join(', ')}`);
    return value;
  }

  date(value, field) {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) this.fail(field, `${field} must be a valid date`);
    return d;
  }

  id(value, field) {
    const n = Number(value);
    if (!Number.isInteger(n) || n <= 0) this.fail(field, `${field} must be a valid id`);
    return n;
  }

  /** Throws a 400 HttpError when any rule failed. */
  assert() {
    if (this.errors.length > 0) {
      const err = new HttpError(400, this.errors[0].message, 'VALIDATION_ERROR');
      err.details = this.errors;
      throw err;
    }
  }
}

module.exports = { Validator, EMAIL_RE };
