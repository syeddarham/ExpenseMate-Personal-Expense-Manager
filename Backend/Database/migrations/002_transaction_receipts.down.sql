-- =====================================================================
-- Rollback for migration 002 - restore transactions.receipt_url
--
-- WARNING: the old column is VARCHAR(500). Receipts longer than 500
-- characters (e.g. base64 images saved after the migration) cannot be
-- copied back and are lost on rollback. Take a backup first
-- (see Assignment02/01_Migration_Report.md).
-- =====================================================================

ALTER TABLE transactions ADD COLUMN receipt_url VARCHAR(500) NULL AFTER tags;

UPDATE transactions t
  JOIN transaction_receipts r ON r.transaction_id = t.id
   SET t.receipt_url = r.content
 WHERE CHAR_LENGTH(r.content) <= 500;

DROP TABLE transaction_receipts;
