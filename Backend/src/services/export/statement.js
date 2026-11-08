/**
 * The format-independent "statement" that every export renderer consumes.
 * Building it once keeps CSV and PDF consistent and makes both testable
 * without a database.
 */

/** Maps a repository transaction row to one statement line. */
function toStatementLine(row) {
  return {
    id: String(row.id),
    date: new Date(row.transaction_date).toISOString().slice(0, 10),
    type: row.type === 'income' ? 'income' : 'expense',
    category: row.category_name || '',
    account: row.account_name || '',
    amount: Number(row.amount),
    note: row.note || '',
    tags: normaliseTags(row.tags),
  };
}

/** Tags are stored as a comma-separated string; tolerate arrays and blanks. */
function normaliseTags(tags) {
  if (!tags) return [];
  const list = Array.isArray(tags) ? tags : String(tags).split(',');
  return list.map((t) => String(t).trim()).filter(Boolean);
}

/** Totals in cents to avoid floating point drift, returned in currency units. */
function summarise(lines) {
  let incomeCents = 0;
  let expenseCents = 0;
  for (const line of lines) {
    const cents = Math.round(line.amount * 100);
    if (line.type === 'income') incomeCents += cents;
    else expenseCents += cents;
  }
  return {
    count: lines.length,
    income: incomeCents / 100,
    expense: expenseCents / 100,
    net: (incomeCents - expenseCents) / 100,
  };
}

/**
 * @param {{ user: object, rows: object[], generatedAt?: Date }} input
 * @returns {{ owner: { name: string, email: string, currencyCode: string, currencySymbol: string },
 *             lines: ReturnType<typeof toStatementLine>[], totals: ReturnType<typeof summarise>, generatedAt: Date }}
 */
function buildStatement({ user, rows, generatedAt = new Date() }) {
  const lines = rows.map(toStatementLine);
  return {
    owner: {
      name: user.full_name,
      email: user.email,
      currencyCode: user.currency_code || 'USD',
      currencySymbol: user.currency_symbol || '$',
    },
    lines,
    totals: summarise(lines),
    generatedAt,
  };
}

module.exports = { buildStatement, toStatementLine, normaliseTags, summarise };
