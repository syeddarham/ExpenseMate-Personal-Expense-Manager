const { BaseRepository } = require('./base.repository');

/** Receipt images/URLs, stored in transaction_receipts since migration 002. */
class ReceiptRepository extends BaseRepository {
  async upsert(transactionId, content) {
    await this.db.query(
      `INSERT INTO transaction_receipts (transaction_id, content) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE content = VALUES(content)`,
      [transactionId, content],
    );
  }

  async delete(transactionId) {
    await this.db.query('DELETE FROM transaction_receipts WHERE transaction_id = ?', [transactionId]);
  }
}

module.exports = { ReceiptRepository };
