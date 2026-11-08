const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { userToJson } = require('../utils/serializers');

/** HTTP layer for /api/users/me. */
function createUserController({ userService }) {
  return {
    getMe: asyncHandler(async (req, res) => {
      res.json({ user: userToJson(await userService.getProfile(req.user.id)) });
    }),

    /** Accepts any subset of profile + preference fields. */
    updateMe: asyncHandler(async (req, res) => {
      const b = req.body;
      const v = new Validator();
      const changes = {};

      if (b.full_name !== undefined || b.name !== undefined) {
        changes.fullName = v.string(b.full_name !== undefined ? b.full_name : b.name, 'full_name', { min: 2, max: 120 });
      }
      if (b.email !== undefined) changes.email = v.email(b.email);
      if (b.avatar_url !== undefined || b.avatar_data !== undefined) {
        const avatar = b.avatar_url !== undefined ? b.avatar_url : b.avatar_data;
        changes.avatarUrl = avatar ? String(avatar) : null;
      }
      if (b.primary_color !== undefined) changes.primaryColor = v.string(b.primary_color, 'primary_color', { min: 4, max: 10 });
      if (b.country !== undefined) changes.country = v.string(b.country, 'country', { max: 100 });
      if (b.preferred_currency !== undefined) {
        const code = v.string(b.preferred_currency, 'preferred_currency', { min: 3, max: 3 });
        changes.currencyCode = code ? code.toUpperCase() : code;
      }
      if (b.currency_symbol !== undefined) changes.currencySymbol = v.string(b.currency_symbol, 'currency_symbol', { max: 10 });
      if (b.dark_mode !== undefined) changes.darkMode = !!b.dark_mode;
      if (b.biometric_enabled !== undefined) changes.biometricEnabled = !!b.biometric_enabled;
      v.assert();

      res.json({ user: userToJson(await userService.updateProfile(req.user.id, changes)) });
    }),

    changePassword: asyncHandler(async (req, res) => {
      const v = new Validator();
      const current = v.string(req.body.current_password, 'current_password', { max: 100 });
      const next = v.password(req.body.new_password, 'new_password');
      v.assert();

      await userService.changePassword(req.user.id, current, next);
      res.json({ message: 'Password updated successfully' });
    }),

    convertCurrency: asyncHandler(async (req, res) => {
      const v = new Validator();
      const currencyCode = v.string(req.body.currency_code, 'currency_code', { min: 2, max: 10 });
      const currencySymbol = v.string(req.body.currency_symbol, 'currency_symbol', { min: 1, max: 10 });
      const convertAmounts = req.body.convert_amounts === true;
      const rate = convertAmounts ? v.positiveNumber(req.body.rate, 'rate') : 1;
      v.assert();

      const user = await userService.changeCurrency(req.user.id, {
        currencyCode: currencyCode.toUpperCase(),
        currencySymbol,
        convertAmounts,
        rate,
      });
      res.json({
        message: convertAmounts ? 'Currency converted successfully' : 'Currency updated successfully',
        user: userToJson(user),
      });
    }),
  };
}

module.exports = { createUserController };
