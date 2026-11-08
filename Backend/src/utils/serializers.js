/**
 * Domain object -> API JSON mappers. Used only by controllers, so the
 * response format (which the Flutter app depends on) is defined in one place.
 */

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

function accountToJson(account) {
  return {
    id: String(account.id),
    name: account.name,
    type: account.type,
    opening_balance: Number(account.opening_balance),
    balance: Number(account.balance !== undefined ? account.balance : account.opening_balance),
  };
}

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

/** One BudgetService.monthlySummary() entry. */
function budgetToJson({ category, limit, spent, monthStart }) {
  return {
    id: String(category.id),
    title: category.name,
    limit_amount: limit,
    spent_amount: spent,
    month: monthStart.toISOString(),
    category: { ...categoryToJson(category), is_expense: true },
  };
}

function overviewToJson(o) {
  return {
    total_balance: o.totalBalance,
    total_income: o.totalIncome,
    total_expense: o.totalExpense,
    total_budget: o.totalBudget,
    recent_transactions: o.recentTransactions.map(transactionToJson),
  };
}

function analyticsToJson(a) {
  return {
    period: a.period,
    total_income: a.totalIncome,
    total_expense: a.totalExpense,
    category_spending: a.categorySpending.map((c) => ({
      category: { ...categoryToJson(c.category), is_expense: true },
      amount: c.amount,
      percentage: c.percentage,
    })),
    trend: a.trend,
  };
}

module.exports = {
  userToJson,
  categoryToJson,
  accountToJson,
  transactionToJson,
  budgetToJson,
  overviewToJson,
  analyticsToJson,
};
