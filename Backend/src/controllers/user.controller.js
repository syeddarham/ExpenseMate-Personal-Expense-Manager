const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { userToJson } = require('../utils/serializers');

/**
 * Profile fields accepted by PUT /api/users/me: request keys (first match
 * wins, older aliases last), the service field name, and how to validate.
 */
const PROFILE_FIELDS = [
  { keys: ['full_name', 'name'], to: 'fullName', parse: (v, x) => v.string(x, 'full_name', { min: 2, max: 120 }) },
  { keys: ['email'], to: 'email', parse: (v, x) => v.email(x) },
  { keys: ['avatar_url', 'avatar_data'], to: 'avatarUrl', parse: (_v, x) => (x ? String(x) : null) },
  { keys: ['primary_color'], to: 'primaryColor', parse: (v, x) => v.string(x, 'primary_color', { min: 4, max: 10 }) },
  { keys: ['country'], to: 'country', parse: (v, x) => v.string(x, 'country', { max: 100 }) },
  {
    keys: ['preferred_currency'],
    to: 'currencyCode',
    parse: (v, x) => v.string(x, 'preferred_currency', { min: 3, max: 3 })?.toUpperCase(),
  },
  { keys: ['currency_symbol'], to: 'currencySymbol', parse: (v, x) => v.string(x, 'currency_symbol', { max: 10 }) },
  { keys: ['dark_mode'], to: 'darkMode', parse: (_v, x) => !!x },
  { keys: ['biometric_enabled'], to: 'biometricEnabled', parse: (_v, x) => !!x },
];

/** HTTP layer for /api/users/me. */
function createUserController({ userService }) {
  return {
    getMe: asyncHandler(async (req, res) => {
      res.json({ user: userToJson(await userService.getProfile(req.user.id)) });
    }),

    /** Accepts any subset of profile + preference fields (see PROFILE_FIELDS). */
    updateMe: asyncHandler(async (req, res) => {
      const v = new Validator();
      const changes = {};
      for (const field of PROFILE_FIELDS) {
        const key = field.keys.find((k) => req.body[k] !== undefined);
        if (key) changes[field.to] = field.parse(v, req.body[key]);
      }
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
