/**
 * RFC 4180 CSV renderer. Every text field goes through one escaping
 * function, and cells starting with = + - @ are prefixed with ' so
 * spreadsheet apps do not execute them as formulas (CSV injection).
 */
const FORMULA_START = /^[=+\-@\t\r]/;

function csvField(value) {
  let text = value === null || value === undefined ? '' : String(value);
  if (FORMULA_START.test(text)) text = `'${text}`;
  return `"${text.replace(/"/g, '""')}"`;
}

/** @param {ReturnType<import('./statement').buildStatement>} statement */
function renderCsv(statement) {
  const symbol = statement.owner.currencySymbol;
  const header = ['ID', 'Date', 'Type', 'Category', 'Account', `Amount (${symbol})`, 'Note', 'Tags'];
  const rows = statement.lines.map((line) => [
    line.id,
    csvField(line.date),
    csvField(line.type),
    csvField(line.category),
    csvField(line.account),
    line.amount.toFixed(2),
    csvField(line.note),
    csvField(line.tags.join(', ')),
  ]);
  const text = [header.join(','), ...rows.map((r) => r.join(','))].join('\r\n');
  return Buffer.from(text, 'utf8');
}

module.exports = { renderCsv, csvField };
