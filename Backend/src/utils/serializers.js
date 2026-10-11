/** Row -> API JSON mappers (keeps controllers free of formatting logic). */

function userToJson(row) {
  return {
    id: String(row.id),
    name: row.full_name,
    email: row.email,
    avatar_url: row.avatar_url,
    country: row.country,
    preferred_currency: row.currency_code,
    currency_symbol: row.currency_symbol,
    primary_color: row.primary_color || '#059669',
    dark_mode: !!row.dark_mode,
    biometric_enabled: !!row.biometric_enabled,
    email_verified: !!row.email_verified,
  };
}

function categoryToJson(row) {
  return {
    id: String(row.id),
    name: row.name,
    icon: row.icon,
    color: row.color,
    is_expense: !!row.is_expense,
    is_custom: row.user_id != null,
  };
}

function accountToJson(row) {
  return {
    id: String(row.id),
    name: row.name,
    type: row.type,
    opening_balance: Number(row.opening_balance),
    balance: Number(row.balance !== undefined ? row.balance : row.opening_balance),
  };
}

/** SELECT used by every endpoint that returns transactions. */
const TRANSACTION_SELECT = `
  SELECT t.id, t.title, t.amount, t.type, t.note, t.tags, t.receipt_url, t.transaction_date,
         t.account_id, a.name AS account_name,
         t.category_id, c.name AS category_name, c.icon AS category_icon,
         c.color AS category_color, c.is_expense AS category_is_expense
  FROM transactions t
  JOIN accounts a   ON a.id = t.account_id
  JOIN categories c ON c.id = t.category_id`;

function transactionToJson(row) {
  return {
    id: String(row.id),
    title: row.title,
    amount: Number(row.amount),
    type: row.type,
    note: row.note,
    tags: row.tags,
    receipt_url: row.receipt_url,
    date: new Date(row.transaction_date).toISOString(),
    account: row.account_name,
    account_id: String(row.account_id),
    category: {
      id: String(row.category_id),
      name: row.category_name,
      icon: row.category_icon,
      color: row.category_color,
      is_expense: !!row.category_is_expense,
    },
  };
}

module.exports = { userToJson, categoryToJson, accountToJson, TRANSACTION_SELECT, transactionToJson };
