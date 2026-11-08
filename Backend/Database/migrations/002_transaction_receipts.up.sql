-- =====================================================================
-- Migration 002 - Move receipts into their own table
--
-- Problem: the Flutter app attaches receipts as base64 data URLs
-- ("data:image/jpeg;base64,...", typically 50 KB - 2 MB), but
-- transactions.receipt_url was VARCHAR(500). In MySQL strict mode every
-- such insert failed with "Data too long", so receipts could never be
-- saved. Storing large blobs inline would also bloat every scan of the
-- transactions table.
--
-- Target: one optional receipt per transaction in transaction_receipts
-- (MEDIUMTEXT, up to 16 MB), deleted automatically with its transaction.
-- The API keeps returning `receipt_url`, so clients need no change.
--
-- Steps: 1) create the new table  2) copy every existing receipt
--        3) drop the old column.
-- =====================================================================

CREATE TABLE IF NOT EXISTS transaction_receipts (
  transaction_id  INT UNSIGNED NOT NULL,
  content         MEDIUMTEXT   NOT NULL,
  created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id),
  CONSTRAINT fk_receipts_transaction FOREIGN KEY (transaction_id)
    REFERENCES transactions (id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO transaction_receipts (transaction_id, content, created_at)
SELECT id, receipt_url, created_at
  FROM transactions
 WHERE receipt_url IS NOT NULL AND receipt_url <> '';

ALTER TABLE transactions DROP COLUMN receipt_url;
