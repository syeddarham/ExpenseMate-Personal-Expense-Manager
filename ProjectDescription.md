# ExpenseMate – Personal Expense Manager

> **Version**: 1.0.0 &nbsp;|&nbsp; **Branch**: IOS  
> **License**: Private  

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Project Directory Structure](#4-project-directory-structure)
5. [Database Schema](#5-database-schema)
6. [Backend REST API](#6-backend-rest-api)
   - 6.1 [Server Configuration](#61-server-configuration)
   - 6.2 [Middleware](#62-middleware)
   - 6.3 [API Endpoints](#63-api-endpoints)
   - 6.4 [Backend Services](#64-backend-services)
   - 6.5 [Backend Utilities](#65-backend-utilities)
7. [Frontend (Flutter)](#7-frontend-flutter)
   - 7.1 [App Entry & Theme](#71-app-entry--theme)
   - 7.2 [Screens (22 Pages)](#72-screens-22-pages)
   - 7.3 [Reusable Components](#73-reusable-components)
   - 7.4 [Models](#74-models)
   - 7.5 [Services](#75-services)
   - 7.6 [Utilities](#76-utilities)
8. [State Management & Caching](#8-state-management--caching)
9. [Authentication Flow](#9-authentication-flow)
10. [Feature Details](#10-feature-details)
11. [Assets](#11-assets)
12. [Environment Variables](#12-environment-variables)
13. [Getting Started](#13-getting-started)

---

## 1. Overview

**ExpenseMate** is a full-stack personal finance management application that enables users to:

- **Track income and expenses** with categorized, dated transactions
- **Manage multiple financial accounts** (cash, bank, card, digital wallet)
- **Set and monitor monthly budgets** per expense category with visual progress indicators
- **View analytical insights** — spending breakdowns, trends over day/week/month/year
- **Attach receipt images** (camera capture or gallery upload) to transactions
- **Export transaction history** as CSV or PDF reports (emailed or downloaded)
- **Customize the app** — choose primary accent color, currency, and country
- **Secure access** — email/password authentication with OTP email verification, forgot/reset password

---

## 2. Architecture

```
┌──────────────────────────────┐
│        Flutter Frontend       │
│  (Dart / Provider / HTTP)     │
│  iOS • Android • Web          │
└──────────┬───────────────────┘
           │  REST / JSON
           │  Bearer JWT Token
           ▼
┌──────────────────────────────┐
│      Node.js + Express API    │
│  (CommonJS / ES modules)      │
│  Port 5000 (default)          │
└──────────┬───────────────────┘
           │  mysql2/promise
           ▼
┌──────────────────────────────┐
│       MySQL Database          │
│  Database: expensemate_db     │
│  Charset: utf8mb4             │
└──────────────────────────────┘
```

**Data flow**: The Flutter app communicates exclusively through the REST API using JSON payloads. Authentication is handled via JWT tokens stored in memory on the client. Important data (transactions, categories, accounts, budgets) is cached locally using `SharedPreferences` with a 15-minute freshness policy to minimize API calls.

---

## 3. Technology Stack

### Frontend
| Component         | Technology / Package                                         |
|--------------------|--------------------------------------------------------------|
| Framework          | Flutter 3.27.4 / Dart 3.6.2                                  |
| State Management   | `provider` ^6.1.2                                            |
| HTTP Client        | `http` ^1.2.1                                                |
| Charts             | `fl_chart` ^0.69.0                                           |
| Fonts              | `google_fonts` ^6.2.1                                        |
| Local Storage      | `shared_preferences` ^2.3.2                                  |
| File Picker        | `file_picker` ^11.0.3                                        |
| Date Formatting    | `intl` ^0.19.0                                               |
| iOS Style Icons    | `cupertino_icons` ^1.0.8                                     |

### Backend
| Component          | Technology / Package                                         |
|--------------------|--------------------------------------------------------------|
| Runtime            | Node.js ≥ 18                                                 |
| Framework          | Express ^4.19.2                                              |
| Database Driver    | mysql2 ^3.11.0 (promise-based connection pool)               |
| Authentication     | jsonwebtoken ^9.0.2, bcryptjs ^2.4.3                         |
| Email              | nodemailer ^6.9.14                                           |
| PDF Generation     | pdfkit ^0.20.2                                               |
| Security           | helmet ^7.1.0, cors ^2.8.5                                   |
| Logging            | morgan ^1.10.0                                               |
| Config             | dotenv ^16.4.5                                               |

### Database
| Component | Technology    |
|-----------|---------------|
| Engine    | MySQL / InnoDB |
| Charset   | utf8mb4       |
| Collation | utf8mb4_unicode_ci |

---

## 4. Project Directory Structure

```
ExpenseMate-Personal-Expense-Manager/
├── Frontend/                             # Flutter frontend client application
│   ├── lib/                              # Flutter frontend source
│   │   ├── main.dart                     # App entry point
│   │   ├── app.dart                      # MaterialApp + ThemeData + Provider setup
│   │   ├── pages/                        # All screen widgets
│   │   │   ├── onboarding/
│   │   │   │   ├── splash_page.dart      # 01_SplashScreen
│   │   │   │   ├── onboarding_page.dart  # 02_Onboarding
│   │   │   │   ├── citizenship_page.dart # 14_Citizenship
│   │   │   │   └── select_currency_page.dart # 15_Select Currency
│   │   │   ├── auth/
│   │   │   │   ├── auth_page.dart        # 03_Auth
│   │   │   │   ├── sign_in_page.dart     # 04_Sign In / 05_Sign In Filled
│   │   │   │   ├── sign_up_page.dart     # 06_Sign Up / 07_Sign Up Filled
│   │   │   │   ├── email_verification_page.dart # 08_Email Verification / 09_Filled
│   │   │   │   ├── forgot_password_page.dart    # 10_Forgot Password
│   │   │   │   ├── reset_password_page.dart     # 11_Reset Password / 12_Filled
│   │   │   │   └── password_reset_success_page.dart # 13_Password Reset Success
│   │   │   ├── home/
│   │   │   │   ├── home_page.dart        # 16_HomeScreen (with bottom nav)
│   │   │   │   └── home_extended_page.dart # 17_HomeScreen Extended (analytics charts)
│   │   │   ├── transaction/
│   │   │   │   ├── transactions_screen.dart # 18_Transactions Screen (all transactions)
│   │   │   │   └── add_transaction_page.dart # 20_Add Transaction Screen
│   │   │   ├── scan/
│   │   │   │   └── scan_screen.dart      # 19_Scan Screen (receipt capture/upload)
│   │   │   ├── budget/
│   │   │   │   └── budget_page.dart      # Budget management page
│   │   │   ├── analytics/
│   │   │   │   └── analytics_page.dart   # Analytics & charts page
│   │   │   ├── category/
│   │   │   │   └── categories_page.dart  # Category CRUD management
│   │   │   ├── account/
│   │   │   │   └── accounts_page.dart    # Account CRUD management
│   │   │   ├── profile/
│   │   │   │   └── profile_page.dart     # User profile & settings
│   │   │   └── login/
│   │   │       └── login_page.dart       # Legacy/alternative login page
│   │   ├── components/                   # Reusable UI widgets
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   ├── app_bar.dart
│   │   │   ├── loading.dart
│   │   │   ├── transaction_card.dart
│   │   │   └── budget_progress_bar.dart
│   │   ├── services/                     # Business logic & API communication
│   │   │   ├── api_service.dart          # HTTP client for all API endpoints
│   │   │   ├── auth_service.dart         # Authentication state (singleton)
│   │   │   ├── expense_state.dart        # Central state manager (ChangeNotifier)
│   │   │   └── currency_service.dart     # Currency utilities
│   │   ├── models/                       # Data models (from/toJson)
│   │   │   ├── user.dart
│   │   │   ├── transaction.dart
│   │   │   ├── category.dart
│   │   │   ├── budget.dart
│   │   │   └── account.dart
│   │   └── utils/                        # Design tokens & helper functions
│   │       ├── constants.dart            # AppColors, AppSpacing, AppShadows
│   │       ├── countries_data.dart       # Country list for onboarding
│   │       ├── currencies_data.dart      # Currency list with symbols & codes
│   │       └── helpers.dart              # Formatting helpers
│   ├── assets/
│   │   ├── icons/
│   │   │   └── budget.png                # App icon / branding image
│   │   └── images/                       # Additional image assets
│   ├── web/
│   │   ├── index.html                    # Web shell HTML
│   │   ├── favicon.png                   # Web favicon (updated with budget.png)
│   │   └── manifest.json                 # PWA manifest
│   ├── android/                          # Android native project
│   ├── ios/                              # iOS native project
│   ├── macos/                            # macOS desktop project
│   ├── windows/                          # Windows desktop project
│   ├── linux/                            # Linux desktop project
│   ├── pubspec.yaml                      # Flutter project configuration
│   └── analysis_options.yaml             # Dart lint rules
├── Backend/                              # Node.js REST API
│   ├── server.js                         # Server entry point (DB init + listen)
│   ├── package.json                      # NPM dependencies
│   ├── .env / .env.example               # Environment configuration
│   ├── Database/
│   │   └── schema.sql                    # MySQL schema (idempotent, auto-run)
│   └── src/
│       ├── app.js                        # Express app setup (middleware + routes)
│       ├── config/
│       │   ├── db.js                     # MySQL connection pool + resilient wrapper
│       │   └── env.js                    # dotenv config loader
│       ├── controllers/
│       │   ├── auth.controller.js        # register, login, verify, forgot/reset
│       │   ├── user.controller.js        # getMe, updateMe, changePassword, convertCurrency
│       │   ├── transaction.controller.js # CRUD + list + export
│       │   ├── category.controller.js    # CRUD + seed defaults
│       │   ├── budget.controller.js      # list + set budget
│       │   ├── account.controller.js     # CRUD
│       │   └── analytics.controller.js   # overview + analytics
│       ├── routes/
│       │   ├── index.js                  # Route aggregator (/api prefix)
│       │   ├── auth.routes.js
│       │   ├── user.routes.js
│       │   ├── transaction.routes.js
│       │   ├── category.routes.js
│       │   ├── budget.routes.js
│       │   ├── account.routes.js
│       │   └── analytics.routes.js
│       ├── middleware/
│       │   ├── auth.js                   # JWT verification (requireAuth)
│       │   └── errorHandler.js           # 404 handler + global error handler
│       ├── services/
│       │   ├── codes.js                  # OTP code issuance & consumption
│       │   ├── export.service.js         # CSV/PDF export generation
│       │   └── mailer.js                 # Nodemailer email sending
│       └── utils/
│           ├── dates.js                  # Date helpers (periodRange, parseMonth)
│           ├── http.js                   # HttpError class + asyncHandler wrapper
│           ├── otp.js                    # OTP generation
│           ├── serializers.js            # DB row → JSON mappers
│           └── validator.js              # Request body validation class
├── AGENTS.md                             # AI agent development guidelines
└── ProjectDescription.md                 # Complete project documentation
```

---

## 5. Database Schema

The database **`expensemate_db`** uses InnoDB engine with `utf8mb4` charset. Schema is auto-initialized on server startup when `AUTO_INIT_DB=true`.

### 5.1 `users` Table
Stores registered user accounts and their preferences.

| Column             | Type            | Constraints                          | Description                          |
|--------------------|-----------------|--------------------------------------|--------------------------------------|
| `id`               | INT UNSIGNED    | PK, AUTO_INCREMENT                   | Unique user identifier               |
| `full_name`        | VARCHAR(120)    | NOT NULL                             | User's display name                  |
| `email`            | VARCHAR(190)    | NOT NULL, UNIQUE                     | Login email address                  |
| `password_hash`    | VARCHAR(255)    | NOT NULL                             | bcrypt-hashed password               |
| `avatar_url`       | MEDIUMTEXT      | NULL                                 | Profile picture (base64 or URL)      |
| `country`          | VARCHAR(100)    | NULL                                 | Selected country                     |
| `currency_code`    | CHAR(3)         | NOT NULL, DEFAULT 'USD'              | ISO currency code                    |
| `currency_symbol`  | VARCHAR(10)     | NOT NULL, DEFAULT '$'                | Currency display symbol              |
| `primary_color`    | VARCHAR(10)     | NOT NULL, DEFAULT '#059669'          | App accent color (hex)               |
| `dark_mode`        | TINYINT(1)      | NOT NULL, DEFAULT 0                  | Dark theme preference                |
| `biometric_enabled`| TINYINT(1)      | NOT NULL, DEFAULT 0                  | Biometric auth preference            |
| `email_verified`   | TINYINT(1)      | NOT NULL, DEFAULT 0                  | Email verification status            |
| `created_at`       | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP            | Account creation time                |
| `updated_at`       | TIMESTAMP       | ON UPDATE CURRENT_TIMESTAMP          | Last profile update time             |

### 5.2 `verification_codes` Table
OTP codes for email verification and password reset. Only SHA-256 hash of code is stored.

| Column       | Type                                              | Description                     |
|--------------|---------------------------------------------------|---------------------------------|
| `id`         | INT UNSIGNED, PK                                  | Code record identifier          |
| `user_id`    | INT UNSIGNED, FK → users(id) ON DELETE CASCADE    | Associated user                 |
| `purpose`    | ENUM('email_verification', 'password_reset')      | Code purpose                    |
| `code_hash`  | CHAR(64)                                          | SHA-256 hash of the 6-digit OTP |
| `attempts`   | TINYINT UNSIGNED, DEFAULT 0                       | Failed attempt counter          |
| `consumed`   | TINYINT(1), DEFAULT 0                             | Whether code has been used      |
| `expires_at` | DATETIME                                          | Expiration timestamp            |

### 5.3 `categories` Table
Per-user transaction categories. Default categories are seeded on registration.

| Column       | Type         | Description                                 |
|--------------|--------------|---------------------------------------------|
| `id`         | INT UNSIGNED | PK, AUTO_INCREMENT                          |
| `user_id`    | INT UNSIGNED | FK → users(id) ON DELETE CASCADE            |
| `name`       | VARCHAR(80)  | Category display name                       |
| `icon`       | VARCHAR(50)  | Material icon name (e.g., 'restaurant')     |
| `color`      | CHAR(7)      | Hex color code (e.g., '#F59E0B')            |
| `is_expense` | TINYINT(1)   | 1 = expense category, 0 = income category   |
| UNIQUE KEY   |              | `(user_id, name)` — prevents duplicates     |

**13 Default Categories** (seeded on registration):

| # | Name              | Icon              | Color     | Type    |
|---|-------------------|-------------------|-----------|---------|
| 1 | Food & Dining     | restaurant        | #F59E0B   | Expense |
| 2 | Groceries         | shopping_cart     | #10B981   | Expense |
| 3 | Transport         | directions_car    | #3B82F6   | Expense |
| 4 | Bills & Utilities | receipt_long      | #8B5CF6   | Expense |
| 5 | Entertainment     | movie             | #EC4899   | Expense |
| 6 | Health            | medical_services  | #EF4444   | Expense |
| 7 | Shopping          | shopping_bag      | #F97316   | Expense |
| 8 | Education         | school            | #0EA5E9   | Expense |
| 9 | Travel            | flight            | #14B8A6   | Expense |
| 10| Salary / Income   | attach_money      | #059669   | Income  |
| 11| Freelance         | work              | #6366F1   | Income  |
| 12| Investments       | trending_up       | #06B6D4   | Income  |
| 13| Gifts             | card_giftcard     | #D946EF   | Income  |

### 5.4 `accounts` Table
Financial payment sources (user-managed, full CRUD).

| Column           | Type           | Description                              |
|------------------|----------------|------------------------------------------|
| `id`             | INT UNSIGNED   | PK, AUTO_INCREMENT                       |
| `user_id`        | INT UNSIGNED   | FK → users(id) ON DELETE CASCADE         |
| `name`           | VARCHAR(80)    | Account display name                     |
| `type`           | ENUM           | 'cash', 'bank', 'card', 'wallet'        |
| `opening_balance`| DECIMAL(14,2)  | Starting balance, DEFAULT 0.00           |
| UNIQUE KEY       |                | `(user_id, name)`                        |

**5 Default Accounts** (seeded on registration):
1. Cash (`cash`)
2. Bank Account (`bank`)
3. Debit Card (`card`)
4. Credit Card (`card`)
5. Digital Wallet (`wallet`)

### 5.5 `transactions` Table
Income and expense records.

| Column             | Type           | Description                                  |
|--------------------|----------------|----------------------------------------------|
| `id`               | INT UNSIGNED   | PK, AUTO_INCREMENT                           |
| `user_id`          | INT UNSIGNED   | FK → users(id) ON DELETE CASCADE             |
| `account_id`       | INT UNSIGNED   | FK → accounts(id) ON DELETE RESTRICT         |
| `category_id`      | INT UNSIGNED   | FK → categories(id) ON DELETE RESTRICT       |
| `title`            | VARCHAR(160)   | Transaction description                      |
| `amount`           | DECIMAL(14,2)  | Transaction amount (CHECK > 0)               |
| `type`             | ENUM           | 'income' or 'expense'                        |
| `note`             | TEXT           | Optional additional notes                    |
| `tags`             | VARCHAR(255)   | Comma-separated tags                         |
| `receipt_url`      | VARCHAR(500)   | Receipt image URL or base64 data             |
| `transaction_date` | DATETIME       | Date/time the transaction occurred           |
| INDEXES            |                | `(user_id, transaction_date)`, `(user_id, category_id)`, `(account_id)` |

### 5.6 `budgets` Table
Monthly spending limits per expense category.

| Column         | Type           | Description                                     |
|----------------|----------------|-------------------------------------------------|
| `id`           | INT UNSIGNED   | PK, AUTO_INCREMENT                              |
| `user_id`      | INT UNSIGNED   | FK → users(id) ON DELETE CASCADE                |
| `category_id`  | INT UNSIGNED   | FK → categories(id) ON DELETE CASCADE           |
| `month_start`  | DATE           | First day of the budget month                   |
| `limit_amount` | DECIMAL(14,2)  | Monthly spending cap (CHECK ≥ 0)                |
| UNIQUE KEY     |                | `(user_id, category_id, month_start)`           |

> Budget limits carry forward: a limit set in an earlier month applies until overridden by a later month's entry.

---

## 6. Backend REST API

### 6.1 Server Configuration

- **Entry Point**: `backend/server.js`
  - Initializes DB schema from `Database/schema.sql` (when `AUTO_INIT_DB=true`)
  - Tests DB pool connectivity
  - Starts Express on configured port (default: 5000)
- **Express App**: `backend/src/app.js`
  - Middleware stack: `helmet` → `cors` → `express.json (10MB limit)` → `express.urlencoded` → `morgan` (dev)
  - All API routes mounted under `/api` prefix
  - 404 handler + global error handler

### 6.2 Middleware

#### `auth.js` — JWT Authentication
- **`requireAuth`**: Validates `Authorization: Bearer <token>` header, verifies JWT signature, loads user from DB, attaches `req.user` (`{id, email, email_verified}`)
- **`signToken(userId)`**: Issues JWT with `sub: userId`, configurable expiry (default: 7 days)

#### `errorHandler.js` — Error Handling
- Translates MySQL errors (`ER_DUP_ENTRY` → 409, `ER_ROW_IS_REFERENCED_2` → 409)
- Handles malformed JSON (400)
- Structured error response: `{ error: { message, code, details? } }`
- Logs 500-level errors to console, sanitizes in production

### 6.3 API Endpoints

All endpoints are prefixed with `/api`. Endpoints marked with 🔒 require a valid JWT Bearer token.

#### Health Check
| Method | Path          | Auth | Description                    |
|--------|---------------|------|--------------------------------|
| GET    | `/api/health` | ❌   | Returns `{ status: "ok", name, timestamp }` |

#### Authentication (`/api/auth`)
| Method | Path                     | Auth | Request Body                                         | Response                                           |
|--------|--------------------------|------|------------------------------------------------------|----------------------------------------------------|
| POST   | `/auth/register`         | ❌   | `{ full_name, email, password, currency_code?, currency_symbol?, country? }` | `201 { message, email }` + sends OTP email         |
| POST   | `/auth/verify-email`     | ❌   | `{ email, code }` (6-digit OTP)                      | `200 { token, user }` — auto-login on verification |
| POST   | `/auth/resend-code`      | ❌   | `{ email, purpose? }`                                | `200 { message }` — rate-limited                   |
| POST   | `/auth/login`            | ❌   | `{ email, password }`                                | `200 { token, user }` or `403 EMAIL_NOT_VERIFIED`  |
| POST   | `/auth/forgot-password`  | ❌   | `{ email }`                                          | `200 { message }` — prevents user enumeration      |
| POST   | `/auth/reset-password`   | ❌   | `{ email, code, new_password }`                      | `200 { message }` — consumes OTP + updates hash    |

**Registration Side Effects**:
- 5 default accounts are seeded for the new user
- 13 default categories (9 expense + 4 income) are seeded
- A 6-digit OTP verification code is emailed

**Login Side Effects**:
- If user has 0 accounts, default accounts are auto-seeded
- Unverified users receive a 403 and a new verification code is issued

#### Users (`/api/users`) 🔒
| Method | Path                 | Description                                           |
|--------|----------------------|-------------------------------------------------------|
| GET    | `/users/me`          | Fetch authenticated user's profile                    |
| PUT    | `/users/me`          | Update profile fields (partial update supported)      |
| PUT    | `/users/me/password` | Change password (requires `current_password`)         |
| PUT    | `/users/me/currency` | Convert currency with optional amount conversion      |

**PUT `/users/me`** — Supported Fields:
- `full_name`, `email`, `avatar_url`/`avatar_data`, `primary_color`, `country`
- `preferred_currency` (currency_code), `currency_symbol`, `dark_mode`, `biometric_enabled`

**PUT `/users/me/currency`** — Currency Conversion:
- Request: `{ currency_code, currency_symbol, convert_amounts, rate }`
- When `convert_amounts: true`, all account balances, transactions, and budget limits are multiplied by the conversion rate in a single transaction

#### Accounts (`/api/accounts`) 🔒
| Method | Path             | Request Body / Params                       | Description                    |
|--------|------------------|---------------------------------------------|--------------------------------|
| GET    | `/accounts`      | —                                           | List all user accounts with computed balances |
| POST   | `/accounts`      | `{ name, type, opening_balance? }`          | Create new account             |
| PUT    | `/accounts/:id`  | `{ name?, type?, opening_balance? }`        | Update account (partial)       |
| DELETE | `/accounts/:id`  | —                                           | Delete account (fails if has transactions via RESTRICT FK) |

**Account Balance Computation**: `opening_balance + SUM(income) - SUM(expense)` — computed dynamically via SQL JOIN.

Valid account types: `cash`, `bank`, `card`, `wallet`

#### Categories (`/api/categories`) 🔒
| Method | Path               | Request Body / Params                        | Description                    |
|--------|--------------------|----------------------------------------------|--------------------------------|
| GET    | `/categories`      | Query: `?type=expense\|income`               | List categories (auto-seeds defaults if empty) |
| POST   | `/categories`      | `{ name, icon, color, is_expense }`          | Create new category            |
| PUT    | `/categories/:id`  | `{ name, icon, color, is_expense }`          | Update category                |
| DELETE | `/categories/:id`  | —                                            | Delete (fails if transactions reference it) |

#### Transactions (`/api/transactions`) 🔒
| Method | Path                    | Query/Body                                          | Description                    |
|--------|-------------------------|-----------------------------------------------------|--------------------------------|
| GET    | `/transactions`         | `?type=&category_id=&account_id=&from=&to=&search=&limit=&offset=` | List transactions (paginated, filterable) |
| GET    | `/transactions/:id`     | —                                                   | Get single transaction         |
| POST   | `/transactions`         | `{ title, amount, type, category_id, account_id?, date?, note?, tags?, receipt_url? }` | Create transaction |
| PUT    | `/transactions/:id`     | Same as POST                                        | Update transaction             |
| DELETE | `/transactions/:id`     | —                                                   | Delete transaction             |
| POST   | `/transactions/export`  | `{ format: "csv"\|"pdf", send_email: bool }`        | Export & email transactions    |

**Smart Category/Account Resolution**: The transaction controller resolves category and account references by numeric ID, name match, or fuzzy search. Falls back to first available if no match.

#### Budgets (`/api/budgets`) 🔒
| Method | Path                   | Query/Body                               | Description                    |
|--------|------------------------|------------------------------------------|--------------------------------|
| GET    | `/budgets`             | `?month=YYYY-MM`                         | List all category budgets for a month with spent amounts |
| PUT    | `/budgets/:categoryId` | `{ limit_amount, month? }`               | Set/update budget limit (upsert) |

**Budget Response** includes: `{ id, title, limit_amount, spent_amount, month, category: {...} }`

#### Analytics & Overview 🔒
| Method | Path             | Query                      | Description                              |
|--------|------------------|----------------------------|------------------------------------------|
| GET    | `/overview`      | —                          | Dashboard summary (balance, month flow, recent 10 transactions, total budget) |
| GET    | `/analytics`     | `?period=day\|week\|month\|year` | Spending analytics with trend data      |

**Overview Response**:
```json
{
  "total_balance": 87453.43,
  "total_income": 5000.00,
  "total_expense": 1500.00,
  "total_budget": 3000.00,
  "recent_transactions": [...]
}
```

**Analytics Response**:
```json
{
  "period": "month",
  "total_income": 5000.00,
  "total_expense": 1500.00,
  "category_spending": [
    { "category": {...}, "amount": 500, "percentage": 33.3 }
  ],
  "trend": [
    { "label": "W1", "expense": 300, "income": 1000 }
  ]
}
```

**Period Bucketing**:
| Period | Buckets | Labels |
|--------|---------|--------|
| `day`  | 8 × 3-hour blocks | `00h`, `03h`, `06h`, ... `21h` |
| `week` | 7 days | `Sun`, `Mon`, `Tue`, ... `Sat` |
| `month`| ~4-5 weekly chunks | `W1`, `W2`, `W3`, `W4`, `W5` |
| `year` | 12 months | `Jan`, `Feb`, ... `Dec` |

### 6.4 Backend Services

#### `codes.js` — OTP Code Management
- **`issueCode(user, purpose)`**: Generates 6-digit OTP, stores SHA-256 hash, sends via email. Rate-limited: 60-second cooldown per purpose.
- **`consumeCode(userId, purpose, code)`**: Validates code hash, checks expiration (10 min) and attempts (max 5). Marks as consumed.

#### `export.service.js` — Transaction Export
- **CSV Generation**: Headers: ID, Date, Type, Category, Account, Amount, Note, Tags
- **PDF Generation** (via pdfkit):
  - Branded header with "ExpenseMate" and "Financial Statement & Transaction History"
  - User metadata box (name, email, currency, generation date)
  - Color-coded table (green for income, red for expense)
  - Summary footer (total income, total expenses, net)
  - Pagination support for large datasets
- **Email Delivery**: Sends export file as email attachment via nodemailer

#### `mailer.js` — Email Service
- SMTP-based email delivery via nodemailer
- Templates: Email verification code, Password reset code, Export attachment

### 6.5 Backend Utilities

#### `validator.js` — Input Validation
Class-based validator that collects all errors before throwing:
- `string(value, field, {min, max, required})` — String validation
- `email(value)` — Email format validation  
- `password(value)` — 8-100 character requirement
- `positiveNumber(value)` — Positive numeric validation
- `nonNegativeNumber(value)` — Zero-or-greater validation
- `oneOf(value, field, options)` — Enum validation
- `date(value)` — Date parsing validation
- `id(value)` — Positive integer validation
- `assert()` — Throws `400 VALIDATION_ERROR` with all collected errors

#### `serializers.js` — Response Formatting
Maps database rows to consistent API JSON format:
- `userToJson(row)` — User profile (excludes password_hash)
- `categoryToJson(row)` — Category with computed `is_custom` flag
- `accountToJson(row)` — Account with computed `balance`
- `transactionToJson(row)` — Full transaction with nested category object

#### `dates.js` — Date Utilities
- `startOfMonth(date)` — First day of the containing month
- `addMonths(date, n)` — Date arithmetic
- `parseMonth(value)` — Parse "YYYY-MM" string with fallback to current month
- `toSqlDate(date)` — Format as MySQL DATE string
- `periodRange(period)` — Generate start/end/buckets for analytics periods

#### `http.js` — HTTP Utilities
- `HttpError` class with `status`, `message`, `code` fields
- `asyncHandler(fn)` — Wraps async route handlers to catch errors

---

## 7. Frontend (Flutter)

### 7.1 App Entry & Theme

**`main.dart`**: Calls `WidgetsFlutterBinding.ensureInitialized()` → `runApp(ExpenseMateApp())`

**`app.dart`**: Sets up:
- `ChangeNotifierProvider<ExpenseState>` wrapping the entire app
- `MaterialApp` with Material 3 theming
- Google Fonts (Inter family) with fallback stack
- Custom `ColorScheme` derived from `AppColors.primary`
- Transparent AppBar with no elevation
- Custom `DialogTheme`, `BottomSheetTheme`, `CardTheme` for consistent white backgrounds

### 7.2 Screens (22 Pages)

| # | Screen Name | File | Description |
|---|-------------|------|-------------|
| 1 | Splash Screen | `pages/onboarding/splash_page.dart` | App logo (wallet icon with gradient), branding text "ExpenseMate" / "Track smarter. Spend better." 2-second auto-navigation to Onboarding |
| 2 | Onboarding | `pages/onboarding/onboarding_page.dart` | Hero finance illustration, "Take Control of Your Money" headline, Terms notice, "Next" button → Auth page |
| 3 | Auth | `pages/auth/auth_page.dart` | Welcome screen with "Sign In" and "Create Account" buttons, wallet icon branding |
| 4 | Sign In | `pages/auth/sign_in_page.dart` | Email/Password fields, Remember Me checkbox, Forgot Password link, Sign In button, Create Account link. Handles `EMAIL_NOT_VERIFIED` redirect |
| 5 | Sign Up | `pages/auth/sign_up_page.dart` | Full Name, Email, Password, Confirm Password fields with validation. Country/currency selection. Terms checkbox. Triggers OTP email |
| 6 | Email Verification | `pages/auth/email_verification_page.dart` | 6-digit OTP input boxes, countdown resend timer, "Verify Email" button. Auto-login on success |
| 7 | Forgot Password | `pages/auth/forgot_password_page.dart` | Email input to receive reset code, "Send Reset Link" button |
| 8 | Reset Password | `pages/auth/reset_password_page.dart` | 6-digit code + New Password + Confirm Password, strength checklist |
| 9 | Password Reset Success | `pages/auth/password_reset_success_page.dart` | Success checkmark animation, "Password Updated!" message, "Sign In" button |
| 10 | Citizenship | `pages/onboarding/citizenship_page.dart` | Searchable country selection list with checkmarks (United States, Singapore, etc.) |
| 11 | Select Currency | `pages/onboarding/select_currency_page.dart` | Currency selector (USD, EUR, GBP, BDT, INR, etc.) with symbol display |
| 12 | Home | `pages/home/home_page.dart` | Main dashboard with bottom navigation bar (Home, Analytics, Add, Budget, Profile). Shows total balance card, income/expense summary, "All Transactions" button, recent transaction list |
| 13 | Home Extended | `pages/home/home_extended_page.dart` | Extended analytics view: Monthly spend chart, savings vs expenses bar chart, category breakdown donut chart |
| 14 | Transactions Screen | `pages/transaction/transactions_screen.dart` | Full transaction list with search, filter by type (All/Income/Expense), filter by account, sort controls, transaction detail modal |
| 15 | Add Transaction | `pages/transaction/add_transaction_page.dart` | Expense/Income toggle, amount input, category selector, account (wallet) selector, date picker, note field, receipt attachment (camera/gallery), Save button |
| 16 | Scan Screen | `pages/scan/scan_screen.dart` | Receipt image capture (camera) and gallery upload. Sends base64-encoded image as `receipt_url` |
| 17 | Budget | `pages/budget/budget_page.dart` | Monthly budget management. Lists all expense categories with progress bars. Set limit popup dialog uses user's currency symbol |
| 18 | Analytics | `pages/analytics/analytics_page.dart` | Spending analytics with period selector (Day/Week/Month/Year), trend line/bar charts, category breakdown with percentages |
| 19 | Categories | `pages/category/categories_page.dart` | Category management with create/edit/delete. Icon picker grid, color picker grid. Separate expense/income tabs |
| 20 | Accounts | `pages/account/accounts_page.dart` | Account CRUD management. Add/edit account name, type, opening balance. Delete confirmation |
| 21 | Profile | `pages/profile/profile_page.dart` | User profile with avatar (image upload), name/email editing, currency change, primary color theme picker, dark mode toggle, biometric toggle, password change, CSV/PDF export, logout |
| 22 | Login Page | `pages/login/login_page.dart` | Alternative/legacy login page |

### 7.3 Reusable Components

| Component | File | Description |
|-----------|------|-------------|
| `CustomButton` | `components/custom_button.dart` | Primary/outlined button with loading spinner, customizable colors & sizing. Respects `AppColors.primary` for dynamic theming |
| `CustomTextField` | `components/custom_text_field.dart` | Styled text field with label, hint, prefix/suffix icons, validation, obscure text support, and error display |
| `CustomAppBar` | `components/app_bar.dart` | Reusable app bar widget with back button and title |
| `LoadingWidget` | `components/loading.dart` | Centered loading spinner with optional message |
| `TransactionCard` | `components/transaction_card.dart` | Transaction list item card showing category icon, title, amount (color-coded), date, and account |
| `BudgetProgressBar` | `components/budget_progress_bar.dart` | Visual progress indicator with percentage, color-coded (green → amber → red based on threshold), budget amounts |

### 7.4 Models

#### `User`
```dart
class User {
  String id, name, email;
  String? avatarUrl, currencySymbol, country;
  String preferredCurrency; // Default: 'USD'
  bool emailVerified, darkMode;
  String primaryColor; // Default: '#059669'
}
```

#### `FinancialTransaction`
```dart
class FinancialTransaction {
  String id, title, account;
  double amount;
  TransactionType type; // enum: income, expense
  TransactionCategory category;
  DateTime date;
  String? note, receiptUrl;
}
```

#### `TransactionCategory`
```dart
class TransactionCategory {
  String id, name;
  IconData icon;
  Color color;
  bool isExpense;
  // Static: 21 icon mappings, 14 color options, 13 default categories
  // Helpers: fromJson, toJson, iconName, colorHex, parseIconName, parseColorHex
}
```

#### `Budget`
```dart
class Budget {
  String id, title;
  double limitAmount, spentAmount;
  TransactionCategory category;
  DateTime month;
  // Computed: remainingAmount, progressPercentage, isExceeded, isNearLimit
}
```

#### `Account`
```dart
class Account {
  String id, name, type; // 'cash', 'bank', 'card', 'wallet'
  double openingBalance, balance;
}
```

### 7.5 Services

#### `ApiService` (`services/api_service.dart`)
Static HTTP client class. Manages all REST API communication:
- **Base URL**: `http://localhost:5000/api` (configurable)
- **Token Management**: Static `_token` field, `setToken()`, `clearToken()`, auto-attached as `Bearer` header
- **Methods** (all static, return parsed Dart objects):
  - `checkHealth()` — Health check with 3s timeout
  - `register(...)` / `verifyEmail(...)` / `resendCode(...)` / `login(...)` — Auth flow
  - `forgotPassword(...)` / `resetPassword(...)` — Password recovery
  - `getMe()` / `updateMe(...)` / `changePassword(...)` — User profile
  - `convertCurrency(...)` — Currency conversion
  - `getAccounts()` / `createAccount(...)` / `updateAccount(...)` / `deleteAccount(...)` — Accounts CRUD
  - `getCategories()` / `createCategory(...)` / `updateCategory(...)` / `deleteCategory(...)` — Categories CRUD
  - `getTransactions(...)` / `addTransaction(...)` / `deleteTransaction(...)` — Transactions
  - `getBudgets(...)` / `setBudget(...)` — Budgets
  - `getOverview()` / `getAnalytics(...)` — Dashboard & analytics
  - `exportTransactions(...)` — CSV/PDF export

#### `AuthService` (`services/auth_service.dart`)
Singleton `ChangeNotifier` managing authentication state:
- **`currentUser`**: The logged-in `User` instance
- **`isAuthenticated`**: Authentication flag
- Wraps `ApiService` auth methods and auto-calls `setUser()` on success
- **`logout()`**: Clears user, token, and auth state

#### `ExpenseState` (`services/expense_state.dart`)
Central state manager (`ChangeNotifier`) provided at app root via `Provider`:
- **Managed Lists**: `_transactions`, `_budgets`, `_accounts`, `_categories`
- **Currency State**: `_currencySymbol`, `_currencyCode`
- **Computed Properties**: `totalIncome`, `totalExpense`, `totalBalance`
- **`loadInitialData()`**: Loads from cache first → API in background
- **Caching Strategy**: Uses `SharedPreferences` keyed by `user_${userId}` prefix
  - 15-minute freshness policy: data is served from cache if fresh, API sync happens in background
  - `_saveToCache()` called after every mutation (add/delete transaction, create account, etc.)
  - Cached entities: transactions, categories, accounts, budgets, currency info
- **CRUD Methods**: `addTransaction()`, `deleteTransaction()`, `addCategory()`, `updateCategory()`, `deleteCategory()`, `addAccount()`, `updateAccount()`, `deleteAccount()`, `setBudget()`, `fetchBudgets()`, `refreshOverview()`
- **`clear()`**: Resets all state for logout

#### `CurrencyService` (`services/currency_service.dart`)
Currency lookup utilities from embedded data.

### 7.6 Utilities

#### `constants.dart` — Design System Tokens

**`AppColors`**:
- Dynamic primary brand color: `primary`, `primaryDark`, `primaryLight` — changeable via `setPrimary(Color)`
- 8 preset primary color palette options
- Financial indicators: `income` (#10B981), `expense` (#EF4444), `warning` (#F59E0B)
- Neutrals: `background`, `surface`, `card`, `border`
- Text: `textPrimary`, `textSecondary`, `textMuted`, `textWhite`
- Dark theme: `darkBackground`, `darkSurface`, `darkCard`, `darkBorder`
- Helpers: `parseHex(String)`, `toHex(Color)`

**`AppSpacing`**: `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48`. Border radii: `radiusSm=8`, `radiusMd=12`, `radiusLg=16`, `radiusXl=24`, `radiusFull=999`

**`AppShadows`**: Card shadow (10px blur, 4px offset), Elevated shadow (20px blur, 8px offset)

#### `countries_data.dart`
Embedded list of ~195 countries with name, ISO code, flag emoji for the onboarding country selection screen.

#### `currencies_data.dart`
Embedded list of ~35 currencies with code, name, symbol for the currency selection screen.

#### `helpers.dart`
Formatting utility functions (currency formatting, date formatting, etc.).

---

## 8. State Management & Caching

### Architecture

```
┌───────────────┐     ┌──────────────────┐     ┌────────────────┐
│  UI Widgets   │ ←── │  ExpenseState    │ ←── │  ApiService    │
│  (Consumer)   │     │  (ChangeNotifier) │     │  (HTTP Client) │
└───────────────┘     └───────┬──────────┘     └────────────────┘
                              │
                      ┌───────▼──────────┐
                      │ SharedPreferences │
                      │ (Local Cache)     │
                      └──────────────────┘
```

### Cache Keys (per user)
- `user_${userId}_transactions` — JSON-encoded transaction list
- `user_${userId}_categories` — JSON-encoded category list
- `user_${userId}_accounts` — JSON-encoded account list
- `user_${userId}_budgets` — JSON-encoded budget list
- `user_${userId}_currency_symbol` — Currency symbol string
- `user_${userId}_currency_code` — Currency code string
- `user_${userId}_last_sync` — Timestamp of last successful API sync

### Freshness Policy
- Cache is considered **fresh** for 15 minutes
- On `loadInitialData()`:
  1. **Immediately** load from `SharedPreferences` cache → notify listeners → UI renders instantly
  2. **In background** (if cache is stale or forced): Fetch from API → merge → save to cache → notify
- **On mutation** (add/delete/update): 
  1. Update local list immediately
  2. Call API
  3. Save to cache via `_saveToCache()`

---

## 9. Authentication Flow

```
1. Splash (2s) → Onboarding → Auth Page
                                  │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
              Sign In Page                  Sign Up Page
                    │                             │
                    │                 ┌────────────┴────────────┐
                    │                 │ (optional)              │
                    │            Citizenship Page         Country/Currency
                    │                 │                   Selection
                    │                 ▼
                    │          POST /auth/register
                    │                 │
                    │                 ▼
                    │        Email Verification Page
                    │         (6-digit OTP input)
                    │                 │
                    │          POST /auth/verify-email
                    │                 │
                    ▼                 ▼
             POST /auth/login    (auto-login)
                    │                 │
                    ▼                 ▼
              ┌─────────────────────────┐
              │  Home Page (Dashboard)   │
              │  + loadInitialData()     │
              └─────────────────────────┘
```

**Password Recovery**:
```
Sign In → Forgot Password → POST /auth/forgot-password → OTP email
→ Reset Password Page → POST /auth/reset-password → Password Reset Success
→ Sign In
```

---

## 10. Feature Details

### 10.1 Transaction Management
- **Add**: Expense/Income toggle with large amount input, category/account pickers, date picker, note, receipt attachment
- **Receipt Attachment**: Camera capture or gallery upload. Image is base64-encoded and sent as `receipt_url`
- **View All**: Dedicated screen with search, type filter, account filter
- **Delete**: Swipe-to-delete or long-press actions

### 10.2 Budget Management
- Monthly budgets per expense category
- Visual progress bars with color indicators:
  - **Green**: < 85% spent
  - **Amber**: 85-100% spent (near limit)
  - **Red**: > 100% spent (exceeded)
- Set limit popup uses the user's configured currency symbol
- Budget limits carry forward automatically to future months

### 10.3 Analytics & Charts (fl_chart)
- **Period Selector**: Day / Week / Month / Year tabs
- **Trend Chart**: Line/bar chart showing income vs expense over bucketed time periods
- **Category Breakdown**: Donut/pie chart with spending percentages per category
- **Financial Summary**: Total income, total expense, net change, % change

### 10.4 Account Management
- Full CRUD: Create, Read, Update, Delete financial accounts
- Dynamic (user-managed, stored in DB)
- Computed running balance: `opening_balance + income - expense`
- 4 account types: Cash, Bank, Card, Wallet

### 10.5 Profile & Settings
- **Avatar**: Image upload (camera/gallery → base64 stored in DB as MEDIUMTEXT)
- **Primary Color**: 8 preset theme colors (Emerald, Blue, Violet, Orange, Rose, Teal, Amber, Red)
- **Currency**: Full currency conversion with rate-based amount recalculation
- **Export**: CSV or PDF reports emailed to user's registered email
- **Security**: Password change with current password verification
- **Logout**: Clears auth state, API token, and local cache

### 10.6 Dynamic Theming
- Primary color is user-configurable and persisted server-side
- `AppColors.setPrimary(Color)` dynamically updates `primary`, `primaryDark`, `primaryLight`
- All UI components reference `AppColors.primary` for consistent theming

---

## 11. Assets

### Icons
| File | Usage |
|------|-------|
| `assets/icons/budget.png` | App branding icon (used in splash, auth, and web favicon) |

### Images
- `assets/images/` — Additional illustrations and onboarding graphics

### Web
| File | Usage |
|------|-------|
| `web/favicon.png` | Browser tab icon |
| `web/index.html` | Web platform shell |
| `web/manifest.json` | PWA manifest with app metadata |

---

## 12. Environment Variables

Backend configuration via `backend/.env`:

| Variable         | Default     | Description                                      |
|------------------|-------------|--------------------------------------------------|
| `PORT`           | `5000`      | Express server port                              |
| `NODE_ENV`       | `development` | Node environment                               |
| `DB_HOST`        | `localhost` | MySQL host                                       |
| `DB_PORT`        | `3306`      | MySQL port                                       |
| `DB_USER`        | `root`      | MySQL username                                   |
| `DB_PASSWORD`    | —           | MySQL password                                   |
| `DB_NAME`        | `expensemate_db` | Database name                                |
| `AUTO_INIT_DB`   | `true`      | Auto-run schema.sql on startup                   |
| `JWT_SECRET`     | —           | Secret key for JWT signing                       |
| `JWT_EXPIRES_IN` | `7d`        | JWT token expiration duration                    |
| `SMTP_HOST`      | —           | SMTP server hostname                             |
| `SMTP_PORT`      | `587`       | SMTP server port                                 |
| `SMTP_USER`      | —           | SMTP authentication username                     |
| `SMTP_PASS`      | —           | SMTP authentication password                     |
| `SMTP_FROM`      | `ExpenseMate <no-reply@expensemate.app>` | Email sender address |

Frontend configuration:
- **API Base URL**: `ApiService.baseUrl` — defaults to `http://localhost:5000/api`, configurable at runtime

---

## 13. Getting Started

### Prerequisites
- **Flutter** ≥ 3.27.4 / **Dart** ≥ 3.6.2
- **Node.js** ≥ 18
- **MySQL** 8.0+ (or compatible MariaDB)
- **SMTP Server** (optional, for email features)

### Backend Setup
```bash
cd backend
cp .env.example .env          # Configure your DB credentials and JWT secret
npm install                    # Install dependencies
npm run db:init                # Initialize database schema (or set AUTO_INIT_DB=true)
npm run dev                    # Start with --watch for development
```

### Frontend Setup
```bash
flutter pub get                # Install Flutter dependencies
flutter analyze                # Check for issues
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on web
```

### API Base URL Configuration
By default, the Flutter app connects to `http://localhost:5000/api`. For physical devices, update `ApiService.baseUrl` to your machine's local IP:
```dart
ApiService.baseUrl = 'http://192.168.x.x:5000/api';
```

---

*Last updated: October 2026*