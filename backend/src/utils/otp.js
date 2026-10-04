const crypto = require('crypto');

/** Generates a zero-padded 6 digit numeric code. */
function generateCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

function hashCode(code) {
  return crypto.createHash('sha256').update(String(code)).digest('hex');
}

module.exports = { generateCode, hashCode };
