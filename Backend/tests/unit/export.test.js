const test = require('node:test');
const assert = require('node:assert/strict');
const { buildStatement, normaliseTags, summarise } = require('../../src/services/export/statement');
const { renderCsv, csvField } = require('../../src/services/export/csv.renderer');
const { renderPdf } = require('../../src/services/export/pdf.renderer');
const { ExportService } = require('../../src/services/export/export.service');
const { fakeRepo } = require('../helpers/fakes');
const { createFakeMailer } = require('../helpers/fakeMailer');

const USER = { id: 7, full_name: 'Test User', email: 'test@example.com', currency_code: 'EUR', currency_symbol: '€' };
const ROWS = [
  {
    id: 2,
    transaction_date: '2026-11-02T10:00:00.000Z',
    type: 'expense',
    category_name: 'Food & Dining',
    account_name: 'Debit Card',
    amount: 12.3,
    note: 'Lunch, with "team"',
    tags: 'work,food',
  },
  {
    id: 1,
    transaction_date: '2026-11-01T09:00:00.000Z',
    type: 'income',
    category_name: 'Salary / Income',
    account_name: 'Bank Account',
    amount: 2500,
    note: null,
    tags: null,
  },
];

test('normaliseTags: comma strings, arrays and blanks', () => {
  assert.deepEqual(normaliseTags('a, b,,c '), ['a', 'b', 'c']);
  assert.deepEqual(normaliseTags(['x', ' y ']), ['x', 'y']);
  assert.deepEqual(normaliseTags(null), []);
});

test('summarise: totals are exact to the cent', () => {
  const lines = [0.1, 0.2, 0.3].map((amount) => ({ type: 'expense', amount }));
  assert.deepEqual(summarise(lines), { count: 3, income: 0, expense: 0.6, net: -0.6 });
});

test('csvField: quotes, doubles embedded quotes and neutralises formulas', () => {
  assert.equal(csvField('a "b", c'), '"a ""b"", c"');
  assert.equal(csvField('=HYPERLINK("x")'), `"'=HYPERLINK(""x"")"`);
  assert.equal(csvField(null), '""');
});

test('renderCsv: header, account names and tags are written (defect D3: Assignment 01 crashed on tags)', () => {
  const csv = renderCsv(buildStatement({ user: USER, rows: ROWS })).toString('utf8');
  const lines = csv.split('\r\n');
  assert.equal(lines[0], 'ID,Date,Type,Category,Account,Amount (€),Note,Tags');
  assert.equal(lines[1], '2,"2026-11-02","expense","Food & Dining","Debit Card",12.30,"Lunch, with ""team""","work, food"');
  assert.equal(lines[2], '1,"2026-11-01","income","Salary / Income","Bank Account",2500.00,"",""');
  assert.equal(lines.length, 3);
});

test('renderPdf: produces a valid multi-page PDF for long statements', async () => {
  const many = Array.from({ length: 120 }, (_, i) => ({ ...ROWS[0], id: i + 1 }));
  const pdf = await renderPdf(buildStatement({ user: USER, rows: many }));
  assert.equal(pdf.subarray(0, 5).toString(), '%PDF-');
  const pages = (pdf.toString('latin1').match(/\/Type \/Page\b/g) || []).length;
  assert.ok(pages >= 3, `expected several pages, got ${pages}`);
});

function makeExportService() {
  const mailer = createFakeMailer();
  const service = new ExportService({
    userRepository: fakeRepo({ findById: (id) => (id === USER.id ? USER : null) }),
    transactionRepository: fakeRepo({ listAll: () => ROWS }),
    mailer,
    clock: () => new Date('2026-11-08T12:00:00Z'),
  });
  return { service, mailer };
}

test('ExportService: CSV export keeps the Assignment 01 response shape', async () => {
  const { service, mailer } = makeExportService();
  const result = await service.exportTransactions(USER.id, { format: 'csv', sendEmail: false });
  assert.deepEqual(Object.keys(result).sort(), ['base64', 'email', 'emailSent', 'filename', 'format', 'recordCount', 'success']);
  assert.equal(result.filename, 'ExpenseMate_Transactions_2026-11-08.csv');
  assert.equal(result.recordCount, 2);
  assert.equal(result.emailSent, false);
  assert.match(Buffer.from(result.base64, 'base64').toString('utf8'), /^ID,Date,Type/);
  assert.equal(mailer.sent.length, 0);
});

test('ExportService: PDF export is e-mailed when requested', async () => {
  const { service, mailer } = makeExportService();
  const result = await service.exportTransactions(USER.id, { format: 'PDF' });
  assert.equal(result.format, 'pdf');
  assert.equal(result.emailSent, true);
  assert.equal(mailer.sent[0].filename, 'ExpenseMate_Transactions_2026-11-08.pdf');
  assert.equal(mailer.sent[0].count, 2);
});

test('ExportService: unknown formats fall back to CSV; unknown users give 404', async () => {
  const { service } = makeExportService();
  assert.equal((await service.exportTransactions(USER.id, { format: 'xml', sendEmail: false })).format, 'csv');
  await assert.rejects(service.exportTransactions(999), { status: 404 });
});
