-- =====================================================================
-- ExpenseMate - Personal Expense Manager
-- MySQL schema (database: expensemate_db)
--
-- All SQL for the project lives in this file. It is idempotent and is
-- executed automatically by the Node.js backend on start-up
-- (see backend/src/config/initDb.js) or manually with:  npm run db:init
-- =====================================================================

CREATE DATABASE IF NOT EXISTS expensemate_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE expensemate_db;

-- ---------------------------------------------------------------------
-- users : registered application users and their preferences
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name           VARCHAR(120)  NOT NULL,
  email               VARCHAR(190)  NOT NULL,
  password_hash       VARCHAR(255)  NOT NULL,
  avatar_url          MEDIUMTEXT    NULL,
  country             VARCHAR(100)  NULL,
  currency_code       CHAR(3)       NOT NULL DEFAULT 'USD',
  currency_symbol     VARCHAR(10)   NOT NULL DEFAULT '$',
  primary_color       VARCHAR(10)   NOT NULL DEFAULT '#059669',
  dark_mode           TINYINT(1)    NOT NULL DEFAULT 0,
  biometric_enabled   TINYINT(1)    NOT NULL DEFAULT 0,
  email_verified      TINYINT(1)    NOT NULL DEFAULT 0,
  created_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- verification_codes : one-time codes for e-mail verification and
-- password reset (only a SHA-256 hash of the code is stored)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS verification_codes (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     INT UNSIGNED NOT NULL,
  purpose     ENUM('email_verification', 'password_reset') NOT NULL,
  code_hash   CHAR(64)     NOT NULL,
  attempts    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  consumed    TINYINT(1)   NOT NULL DEFAULT 0,
  expires_at  DATETIME     NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_codes_user_purpose (user_id, purpose, created_at),
  CONSTRAINT fk_codes_user FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- categories : strictly scoped per user account
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     INT UNSIGNED NOT NULL,
  name        VARCHAR(80)  NOT NULL,
  icon        VARCHAR(50)  NOT NULL DEFAULT 'category',
  color       CHAR(7)      NOT NULL DEFAULT '#10B981',
  is_expense  TINYINT(1)   NOT NULL DEFAULT 1,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_user_name (user_id, name),
  CONSTRAINT fk_categories_user FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- accounts : cash, bank, card and digital-wallet payment sources
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS accounts (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id          INT UNSIGNED NOT NULL,
  name             VARCHAR(80)  NOT NULL,
  type             ENUM('cash', 'bank', 'card', 'wallet') NOT NULL DEFAULT 'cash',
  opening_balance  DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_accounts_user_name (user_id, name),
  CONSTRAINT fk_accounts_user FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- transactions : income and expense records
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           INT UNSIGNED NOT NULL,
  account_id        INT UNSIGNED NOT NULL,
  category_id       INT UNSIGNED NOT NULL,
  title             VARCHAR(160) NOT NULL,
  amount            DECIMAL(14,2) NOT NULL,
  type              ENUM('income', 'expense') NOT NULL,
  note              TEXT         NULL,
  tags              VARCHAR(255) NULL,
  receipt_url       VARCHAR(500) NULL,
  transaction_date  DATETIME     NOT NULL,
  created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tx_user_date (user_id, transaction_date),
  KEY idx_tx_user_category (user_id, category_id),
  KEY idx_tx_account (account_id),
  CONSTRAINT chk_tx_amount CHECK (amount > 0),
  CONSTRAINT fk_tx_user FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_tx_account FOREIGN KEY (account_id)
    REFERENCES accounts (id) ON DELETE RESTRICT,
  CONSTRAINT fk_tx_category FOREIGN KEY (category_id)
    REFERENCES categories (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- budgets : monthly spending limit per expense category.
-- A limit applies from its month_start until a later month overrides it.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS budgets (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       INT UNSIGNED NOT NULL,
  category_id   INT UNSIGNED NOT NULL,
  month_start   DATE         NOT NULL,
  limit_amount  DECIMAL(14,2) NOT NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_budget_user_cat_month (user_id, category_id, month_start),
  CONSTRAINT chk_budget_limit CHECK (limit_amount >= 0),
  CONSTRAINT fk_budgets_user FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_budgets_category FOREIGN KEY (category_id)
    REFERENCES categories (id) ON DELETE CASCADE
) ENGINE=InnoDB;
