const PDFDocument = require('pdfkit');

/** Layout constants (previously magic numbers scattered through the drawing code). */
const PAGE = { size: 'A4', margin: 40, width: 515, bottom: 740 };
const ROW_HEIGHT = 20;
const COLORS = {
  brand: '#059669',
  muted: '#6B7280',
  text: '#111827',
  body: '#374151',
  zebra: '#F9FAFB',
  border: '#E5E7EB',
  income: '#10B981',
  expense: '#EF4444',
  summaryFill: '#F0FDF4',
  summaryBorder: '#86EFAC',
  summaryText: '#065F46',
  white: '#FFFFFF',
};
const COLUMNS = [
  { title: 'Date', x: 45, width: 65, value: (l) => l.date },
  { title: 'Category', x: 115, width: 95, value: (l) => l.category || '-' },
  { title: 'Type', x: 215, width: 55, value: (l) => (l.type === 'income' ? 'Income' : 'Expense') },
  { title: 'Account', x: 275, width: 75, value: (l) => l.account || '-' },
  { title: 'Note', x: 355, width: 110, value: (l) => l.note || '-' },
];
const AMOUNT_COLUMN = { title: 'Amount', x: 470, width: 80 };

function money(symbol, n) {
  return `${symbol}${n.toFixed(2)}`;
}

/**
 * Renders the statement as an A4 PDF.
 * @param {ReturnType<import('./statement').buildStatement>} statement
 * @returns {Promise<Buffer>}
 */
function renderPdf(statement) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: PAGE.margin, size: PAGE.size });
    const chunks = [];
    doc.on('data', (c) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    drawHeader(doc, statement);
    let y = drawTableHeader(doc, doc.y + 10);
    statement.lines.forEach((line, i) => {
      if (y > PAGE.bottom) {
        doc.addPage();
        y = PAGE.margin;
      }
      drawRow(doc, line, i, y, statement.owner.currencySymbol);
      y += ROW_HEIGHT;
    });
    drawSummary(doc, statement, y);
    doc.end();
  });
}

function drawHeader(doc, { owner, lines, generatedAt }) {
  doc.fillColor(COLORS.brand).fontSize(22).font('Helvetica-Bold').text('ExpenseMate');
  doc.fillColor(COLORS.muted).fontSize(10).font('Helvetica').text('Financial Statement & Transaction History');
  doc.moveDown(0.8);

  const boxY = doc.y;
  doc.rect(PAGE.margin, boxY, PAGE.width, 60).fillAndStroke(COLORS.zebra, COLORS.border);
  doc.fillColor(COLORS.text).fontSize(10).font('Helvetica-Bold').text(`Account: ${owner.name} (${owner.email})`, 55, boxY + 12);
  doc
    .fillColor(COLORS.muted)
    .fontSize(9)
    .font('Helvetica')
    .text(`Currency: ${owner.currencyCode} (${owner.currencySymbol})   |   Generated: ${generatedAt.toLocaleString()}`, 55, boxY + 28);
  doc.text(`Total Records: ${lines.length}`, 55, boxY + 42);
  doc.moveDown(3);
}

function drawTableHeader(doc, top) {
  doc.rect(PAGE.margin, top, PAGE.width, 22).fill(COLORS.brand);
  doc.fillColor(COLORS.white).fontSize(9).font('Helvetica-Bold');
  for (const col of COLUMNS) doc.text(col.title, col.x, top + 6, { width: col.width });
  doc.text(AMOUNT_COLUMN.title, AMOUNT_COLUMN.x, top + 6, { width: AMOUNT_COLUMN.width, align: 'right' });
  doc.font('Helvetica').fontSize(8.5);
  return top + 24;
}

function drawRow(doc, line, index, y, symbol) {
  if (index % 2 === 0) doc.rect(PAGE.margin, y, PAGE.width, ROW_HEIGHT).fill(COLORS.zebra);
  doc.fillColor(COLORS.body);
  for (const col of COLUMNS) doc.text(col.value(line), col.x, y + 5, { width: col.width, ellipsis: true });

  const isIncome = line.type === 'income';
  doc
    .fillColor(isIncome ? COLORS.income : COLORS.expense)
    .font('Helvetica-Bold')
    .text(`${isIncome ? '+' : '-'}${money(symbol, line.amount)}`, AMOUNT_COLUMN.x, y + 5, {
      width: AMOUNT_COLUMN.width,
      align: 'right',
    });
  doc.font('Helvetica');
}

function drawSummary(doc, { owner, totals }, y) {
  if (y + 50 > PAGE.bottom + 10) {
    doc.addPage();
    y = PAGE.margin;
  }
  const s = owner.currencySymbol;
  doc.rect(PAGE.margin, y + 10, PAGE.width, 36).fillAndStroke(COLORS.summaryFill, COLORS.summaryBorder);
  doc
    .fillColor(COLORS.summaryText)
    .fontSize(10)
    .font('Helvetica-Bold')
    .text(
      `Total Income: +${money(s, totals.income)}    |    Total Expenses: -${money(s, totals.expense)}    |    Net: ${money(s, totals.net)}`,
      55,
      y + 22,
    );
}

module.exports = { renderPdf };
