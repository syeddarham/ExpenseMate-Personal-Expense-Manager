const jwt = require('jsonwebtoken');

/** Issues and verifies the JWT bearer tokens used by the Flutter client. */
class TokenService {
  constructor({ secret, expiresIn = '7d' }) {
    if (!secret) throw new Error('JWT secret is not configured (set JWT_SECRET in .env)');
    this.secret = secret;
    this.expiresIn = expiresIn;
  }

  sign(userId) {
    return jwt.sign({ sub: userId }, this.secret, { expiresIn: this.expiresIn });
  }

  /** @returns {number|string|null} the user id, or null when the token is invalid/expired */
  verify(token) {
    try {
      return jwt.verify(token, this.secret).sub;
    } catch (_) {
      return null;
    }
  }
}

module.exports = { TokenService };
