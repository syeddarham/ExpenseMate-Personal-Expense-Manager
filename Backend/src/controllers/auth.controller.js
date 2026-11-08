const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { userToJson } = require('../utils/serializers');

/** HTTP layer for /api/auth: validate input -> AuthService -> JSON. */
function createAuthController({ authService }) {
  return {
    register: asyncHandler(async (req, res) => {
      const v = new Validator();
      const fullName = v.string(req.body.full_name, 'full_name', { min: 2, max: 120 });
      const email = v.email(req.body.email);
      const password = v.password(req.body.password);
      v.assert();

      await authService.register({
        fullName,
        email,
        password,
        currencyCode: req.body.currency_code || undefined,
        currencySymbol: req.body.currency_symbol || undefined,
        country: req.body.country || null,
      });
      res.status(201).json({ message: 'Account created. A verification code has been sent to your email.', email });
    }),

    verifyEmail: asyncHandler(async (req, res) => {
      const v = new Validator();
      const email = v.email(req.body.email);
      const code = v.string(req.body.code, 'code', { min: 6, max: 6 });
      v.assert();

      const { token, user } = await authService.verifyEmail(email, code);
      res.json({ token, user: userToJson(user) });
    }),

    resendCode: asyncHandler(async (req, res) => {
      const v = new Validator();
      const email = v.email(req.body.email);
      v.assert();

      const purpose = req.body.purpose === 'password_reset' ? 'password_reset' : 'email_verification';
      await authService.resendCode(email, purpose);
      res.json({ message: 'If the account exists, a new code has been sent.' });
    }),

    login: asyncHandler(async (req, res) => {
      const v = new Validator();
      const email = v.email(req.body.email);
      const password = v.string(req.body.password, 'password', { max: 100 });
      v.assert();

      const { token, user } = await authService.login(email, password);
      res.json({ token, user: userToJson(user) });
    }),

    forgotPassword: asyncHandler(async (req, res) => {
      const v = new Validator();
      const email = v.email(req.body.email);
      v.assert();

      await authService.forgotPassword(email);
      res.json({ message: 'If an account exists for this email, a reset code has been sent.' });
    }),

    resetPassword: asyncHandler(async (req, res) => {
      const v = new Validator();
      const email = v.email(req.body.email);
      const code = v.string(req.body.code, 'code', { min: 6, max: 6 });
      const newPassword = v.password(req.body.new_password, 'new_password');
      v.assert();

      await authService.resetPassword(email, code, newPassword);
      res.json({ message: 'Password updated successfully' });
    }),
  };
}

module.exports = { createAuthController };
