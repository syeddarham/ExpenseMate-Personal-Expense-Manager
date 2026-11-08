const { asyncHandler } = require('../utils/http');
const { Validator } = require('../utils/validator');
const { accountToJson } = require('../utils/serializers');
const { ACCOUNT_TYPES } = require('../services/account.service');

/** HTTP layer for /api/accounts. */
function createAccountController({ accountService }) {
  return {
    list: asyncHandler(async (req, res) => {
      const accounts = await accountService.list(req.user.id);
      res.json({ accounts: accounts.map(accountToJson) });
    }),

    create: asyncHandler(async (req, res) => {
      const v = new Validator();
      const name = v.string(req.body.name, 'name', { max: 80 });
      const type = v.oneOf(req.body.type || 'cash', 'type', ACCOUNT_TYPES);
      const openingBalance = optionalNumber(v, req.body.opening_balance, 'opening_balance') ?? 0;
      v.assert();

      const account = await accountService.create(req.user.id, { name, type, openingBalance });
      res.status(201).json({ account: accountToJson(account) });
    }),

    update: asyncHandler(async (req, res) => {
      const v = new Validator();
      const id = v.id(req.params.id, 'id');
      const changes = {};
      if (req.body.name !== undefined) changes.name = v.string(req.body.name, 'name', { max: 80 });
      if (req.body.type !== undefined) changes.type = v.oneOf(req.body.type, 'type', ACCOUNT_TYPES);
      if (req.body.opening_balance !== undefined) {
        changes.openingBalance = optionalNumber(v, req.body.opening_balance, 'opening_balance');
      }
      v.assert();

      res.json({ account: accountToJson(await accountService.update(id, req.user.id, changes)) });
    }),

    remove: asyncHandler(async (req, res) => {
      const v = new Validator();
      const id = v.id(req.params.id, 'id');
      v.assert();

      await accountService.delete(id, req.user.id);
      res.json({ message: 'Account deleted' });
    }),
  };
}

function optionalNumber(v, value, field) {
  if (value === undefined) return undefined;
  const n = Number(value);
  if (!Number.isFinite(n)) v.fail(field, `${field} must be a number`);
  return n;
}

module.exports = { createAccountController };
