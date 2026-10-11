const PDFDocument = require('pdfkit');
const { pool } = require('../config/db');
const { TRANSACTION_SELECT, transactionToJson } = require('../utils/serializers');
const { sendExportEmail } = require('./mailer');

/**
 * Generates CSV string for transactions.
 */
function generateCsv(transactions, currencySymbol = '$') {
  const headers = ['ID', 'Date', 'Type', 'Category', 'Account', `Amount (${currencySymbol})`, 'Note', 'Tags'];
  const rows = transactions.map((t) => [
    t.id,
    `"${new Date(t.date).toISOString().slice(0, 10)}"`,
    `"${t.type}"`,
    `"${(t.category && t.category.name) ? t.category.name.replace(/"/g, '""') : ''}"`,
    `"${(t.account && t.account.name) ? t.account.name.replace(/"/g, '""') : ''}"`,
    t.amount.toFixed(2),
    `"${(t.note || '').replace(/"/g, '""')}"`,
    `"${(t.tags ? t.tags.join(', ') : '').replace(/"/g, '""')}"`,
  ]);

  return [headers.join(','), ...rows.map((r) => r.join(','))].join('\r\n');
}

/**
 * Generates PDF buffer for transactions using pdfkit.
 */
function generatePdf(transactions, user, currencySymbol = '$') {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 40, size: 'A4' });
    const buffers = [];

    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);

    // Header Branding
    doc.fillColor('#059669').fontSize(22).font('Helvetica-Bold').text('ExpenseMate', { align: 'left' });
    doc.fillColor('#6B7280').fontSize(10).font('Helvetica').text('Financial Statement & Transaction History', { align: 'left' });
    doc.moveDown(0.8);

    // Metadata Box
    doc.rect(40, doc.y, 515, 60).fillAndStroke('#F9FAFB', '#E5E7EB');
    const boxY = doc.y + 12;
    doc.fillColor('#111827').fontSize(10).font('Helvetica-Bold').text(`Account: ${user.full_name} (${user.email})`, 55, boxY);
    doc.fillColor('#6B7280').fontSize(9).font('Helvetica').text(`Currency: ${user.currency_code || 'USD'} (${currencySymbol})   |   Generated: ${new Date().toLocaleString()}`, 55, boxY + 16);
    doc.text(`Total Records: ${transactions.length}`, 55, boxY + 30);
    doc.moveDown(3);

    // Table Header
    const tableTop = doc.y + 10;
    doc.rect(40, tableTop, 515, 22).fill('#059669');
    doc.fillColor('#FFFFFF').fontSize(9).font('Helvetica-Bold');
    doc.text('Date', 45, tableTop + 6, { width: 65 });
    doc.text('Category', 115, tableTop + 6, { width: 95 });
    doc.text('Type', 215, tableTop + 6, { width: 55 });
    doc.text('Account', 275, tableTop + 6, { width: 75 });
    doc.text('Note', 355, tableTop + 6, { width: 110 });
    doc.text('Amount', 470, tableTop + 6, { width: 80, align: 'right' });

    let currentY = tableTop + 24;
    doc.font('Helvetica').fontSize(8.5);

    transactions.forEach((t, i) => {
      if (currentY > 740) {
        doc.addPage();
        currentY = 40;
      }

      // Alternate row backgrounds
      if (i % 2 === 0) {
        doc.rect(40, currentY, 515, 20).fill('#F9FAFB');
      }

      const isExpense = t.type === 'expense';
      const dateStr = new Date(t.date).toISOString().slice(0, 10);
      const catName = (t.category && t.category.name) ? t.category.name : '-';
      const accName = (t.account && t.account.name) ? t.account.name : '-';
      const noteStr = t.note || '-';
      const amountStr = `${isExpense ? '-' : '+'}${currencySymbol}${t.amount.toFixed(2)}`;

      doc.fillColor('#374151');
      doc.text(dateStr, 45, currentY + 5, { width: 65 });
      doc.text(catName, 115, currentY + 5, { width: 95, ellipsis: true });
      doc.text(isExpense ? 'Expense' : 'Income', 215, currentY + 5, { width: 55 });
      doc.text(accName, 275, currentY + 5, { width: 75, ellipsis: true });
      doc.text(noteStr, 355, currentY + 5, { width: 110, ellipsis: true });

      // Amount color
      doc.fillColor(isExpense ? '#EF4444' : '#10B981').font('Helvetica-Bold');
      doc.text(amountStr, 470, currentY + 5, { width: 80, align: 'right' });
      doc.font('Helvetica');

      currentY += 20;
    });

    // Summary at bottom
    doc.moveDown(2);
    if (currentY + 50 > 750) {
      doc.addPage();
      currentY = 40;
    }
    const totalIncome = transactions.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
    const totalExpense = transactions.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);

    doc.rect(40, currentY + 10, 515, 36).fillAndStroke('#F0FDF4', '#86EFAC');
    doc.fillColor('#065F46').fontSize(10).font('Helvetica-Bold');
    doc.text(`Total Income: +${currencySymbol}${totalIncome.toFixed(2)}    |    Total Expenses: -${currencySymbol}${totalExpense.toFixed(2)}    |    Net: ${currencySymbol}${(totalIncome - totalExpense).toFixed(2)}`, 55, currentY + 22);

    doc.end();
  });
}

/**
 * Exports user transactions and emails or returns file buffer.
 */
async function exportUserTransactions(userId, { format = 'csv', sendEmail = true } = {}) {
  const [userRows] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);
  if (userRows.length === 0) throw new Error('User not found');
  const user = userRows[0];
  const currencySymbol = user.currency_symbol || '$';

  const [txRows] = await pool.query(
    `${TRANSACTION_SELECT} WHERE t.user_id = ? ORDER BY t.transaction_date DESC, t.id DESC`,
    [userId]
  );
  const transactions = txRows.map(transactionToJson);

  const timestamp = new Date().toISOString().slice(0, 10);
  const isPdf = format.toLowerCase() === 'pdf';
  let buffer;
  let filename;

  if (isPdf) {
    buffer = await generatePdf(transactions, user, currencySymbol);
    filename = `ExpenseMate_Transactions_${timestamp}.pdf`;
  } else {
    const csv = generateCsv(transactions, currencySymbol);
    buffer = Buffer.from(csv, 'utf8');
    filename = `ExpenseMate_Transactions_${timestamp}.csv`;
  }

  let emailSent = false;
  if (sendEmail && user.email) {
    emailSent = await sendExportEmail(user.email, {
      format: isPdf ? 'PDF' : 'CSV',
      buffer,
      filename,
      count: transactions.length,
      currencySymbol,
    });
  }

  return {
    success: true,
    format: isPdf ? 'pdf' : 'csv',
    filename,
    email: user.email,
    emailSent,
    recordCount: transactions.length,
    base64: buffer.toString('base64'),
  };
}

module.exports = {
  exportUserTransactions,
  generateCsv,
  generatePdf,
};
