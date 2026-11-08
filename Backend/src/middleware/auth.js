const { asyncHandler } = require('../utils/http');

/** Requires a valid Bearer token and attaches the user to req.user. */
function createRequireAuth({ authService }) {
  return asyncHandler(async (req, _res, next) => {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    req.user = await authService.authenticate(token);
    next();
  });
}

module.exports = { createRequireAuth };
