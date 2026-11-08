const { NotFoundError } = require('../../utils/http');
const { buildStatement } = require('./statement');
const { renderCsv } = require('./csv.renderer');
const { renderPdf } = require('./pdf.renderer');

/** Output formats. Adding one (e.g. XLSX) means adding an entry here, nothing else. */
const DEFAULT_FORMATS = {
  csv: { label: 'CSV', extension: 'csv', render: renderCsv },
  pdf: { label: 'PDF', extension: 'pdf', render: renderPdf },
};

/**
 * Rewritten export module (Assignment 02, Part C).
 *
 * Coordinates the export only: load data through repositories, build a
 * statement, hand it to the chosen renderer, optionally e-mail the file.
 * Formatting lives in the renderers; data access lives in repositories.
 */
class ExportService {
  constructor({ userRepository, transactionRepository, mailer, formats = DEFAULT_FORMATS, clock = () => new Date() }) {
    this.users = userRepository;
    this.transactions = transactionRepository;
    this.mailer = mailer;
    this.formats = formats;
    this.clock = clock;
  }

  /** Unknown formats fall back to CSV (same as Assignment 01). */
  resolveFormat(format) {
    const key = String(format || 'csv').toLowerCase();
    return this.formats[key] ? key : 'csv';
  }

  /**
   * @returns {Promise<{ success: true, format: string, filename: string, email: string, emailSent: boolean,
   *                     recordCount: number, base64: string }>}
   */
  async exportTransactions(userId, { format = 'csv', sendEmail = true } = {}) {
    const user = await this.users.findById(userId);
    if (!user) throw new NotFoundError('User not found');

    const key = this.resolveFormat(format);
    const spec = this.formats[key];
    const now = this.clock();
    const statement = buildStatement({ user, rows: await this.transactions.listAll(userId), generatedAt: now });
    const buffer = await spec.render(statement);
    const filename = `ExpenseMate_Transactions_${now.toISOString().slice(0, 10)}.${spec.extension}`;

    let emailSent = false;
    if (sendEmail && user.email) {
      emailSent = await this.mailer.sendExportEmail(user.email, {
        format: spec.label,
        buffer,
        filename,
        count: statement.totals.count,
        currencySymbol: statement.owner.currencySymbol,
      });
    }

    return {
      success: true,
      format: key,
      filename,
      email: user.email,
      emailSent,
      recordCount: statement.totals.count,
      base64: buffer.toString('base64'),
    };
  }
}

module.exports = { ExportService, DEFAULT_FORMATS };
