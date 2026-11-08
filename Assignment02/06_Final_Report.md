# ExpenseMate — Assignment 02 Final Report

**Software Evolution: Migration, Refactoring and Rewriting**

| | |
|---|---|
| Project | ExpenseMate — Personal Expense Manager (Flutter + Node.js/Express + MySQL) |
| Team | _[Member 1 name — Team Lead]_, _[Member 2 name]_ |
| Baseline | git tag `a01-baseline` (`59c3c27`) · Work: branch `assignment-02` |
| Detailed reports | [01 Migration](01_Migration_Report.md) · [02 Refactoring](02_Refactoring_Report.md) · [03 Rewriting](03_Rewriting_Report.md) · [04 Tests](04_Test_Report.md) · [05 Metrics and change log](05_Maintainability_and_Changelog.md) |

## 1. Starting point and code review

We continued from the Assignment 01 code. A review before any changes found these maintenance problems:

1. **No layering in the backend.**
   - All 7 controllers ran SQL directly through a global connection pool and mixed validation, business rules and JSON formatting.
   - In total, 11 files outside a data layer executed SQL.
   - The most complex function (`parseTransactionBody`, cyclomatic complexity 27) lived in a controller.
2. **The schema could not evolve.** A single `schema.sql` with `CREATE TABLE IF NOT EXISTS` cannot change an existing table, and nothing recorded which schema a database had.
3. **Classes doing too much:**
   - the export module (SQL + CSV + PDF + e-mail);
   - the Flutter `ApiService` (27 copies of the same request/error code; untestable).
4. **No automated tests** in the backend, and one smoke test in Flutter.
5. **Secrets in git.** The real `.env` and a production dump were committed.

The review and the new tests found **five defects** in Assignment 01 (D1–D5 in the [defect log](04_Test_Report.md#6-defect-log)), four of them confirmed by running tests against the baseline:

- **D1:** receipt uploads always failed (500);
- **D2:** the dashboard budget total was double-counted;
- **D3:** the export had an empty Account column and crashed on tagged transactions;
- **D4:** the Flutter app never saved the selected currency.

## 2. Part A — Migration

**What:** we replaced the one-shot `schema.sql` with **versioned migrations** (`Database/migrations/NNN_name.up/down.sql`) and a runner (`src/database/migrator.js`). The runner:
- records each applied version and its SHA-256 checksum in `schema_migrations`;
- refuses to run if an applied migration was edited afterwards;
- takes a MySQL lock so two servers can't migrate at once;
- supports rollback.

- **Migration 001** is the Assignment 01 schema. Existing databases adopt it as a no-op.
- **Migration 002** moves receipts from `transactions.receipt_url VARCHAR(500)` into a new `transaction_receipts` table (`MEDIUMTEXT`, cascade delete). It copies the existing data first, then drops the column.

**Why:** the app stores receipts as base64 images (tens of KB to MB), so every receipt upload failed with `ER_DATA_TOO_LONG` (D1). The fix needed a repeatable way to change an existing schema.

**Verification:**
- **Production-data rehearsal.** We loaded a copy of the production dump into a throwaway MySQL, fingerprinted every row, ran the real `npm run migrate` CLI and compared. All 3 users, 15 accounts, 44 categories and 12 transactions were present and unchanged; a second run was a no-op ([evidence](evidence/migration-rehearsal.txt)).
- **Integration tests** cover receipt copying, the 200 KB receipt case (fails on the old schema, works after), rollback, and checksum drift.

**Supplementary migration:** secrets and the API endpoint moved out of source code into `.env` / `--dart-define=API_BASE_URL`.

**Risks:**
- MySQL DDL is not transactional, so take a backup first.
- Rolling back loses receipts longer than 500 characters.
- **Migration 002 has not been run on the production server yet**; the procedure is in report 01.

## 3. Part B — Refactoring to Controller → Services → Repository → Database

All 7 backend modules now follow the required flow:

- **Controllers** validate the input shape, call one service and serialise JSON.
- **Services** (10) hold the business rules:
  - account balance;
  - budget carry-forward;
  - category/account resolution for new transactions;
  - OTP rules;
  - currency conversion;
  - analytics percentages and trend buckets.
- **Repositories** (7) are the only code that runs SQL.
- **The Database layer** is a pool wrapper that lets one service run several repositories inside a single DB transaction.
- **`container.js`** wires everything in one direction, and **`tests/unit/architecture.test.js` fails the build if any file imports against that direction.**

**Required features:**
- **Add Transaction / Add Expense** (`POST /api/transactions`): Controller → `TransactionService` → Category/Account/Transaction/Receipt repositories → MySQL.
- **Monthly Budget Summary** (`GET /api/budgets`): the carry-forward rule moved out of a correlated SQL sub-query into `BudgetService.effectiveLimits()`. The dashboard now reuses it, which fixed D2.

Diagrams and the full trace are in [report 02](02_Refactoring_Report.md).

**Quality improvements (measured):**
1. SQL outside the data layer: 11 files → 0.
2. Average complexity: 3.80 → 2.19; maximum: 27 → 12; functions above 10: 6 → 1.
3. Controller size: 866 → 355 lines.
4. Testability: services take their repositories as constructor arguments, so 69 backend tests (90.8% line coverage) run against fakes or a throwaway database.

## 4. Part C — Rewriting two classes

1. **Backend export module** (`services/export.service.js` → `services/export/`).
   - **Problem:** one module did four jobs, had about 80 inline layout numbers, and had two bugs (D3).
   - **New design:**
     - `buildStatement()` creates one format-independent statement, with totals computed in cents;
     - `renderCsv()` does RFC 4180 escaping and guards against spreadsheet formula injection;
     - `renderPdf()` uses a layout-constant table;
     - `ExportService` only coordinates repositories → statement → renderer → mailer.
   - **Kept:** the response shape and file formats. 8 unit tests.
2. **Flutter `ApiService`.**
   - **Problem:** 27 methods each re-implemented try/catch, the HTTP call, JSON decoding and error extraction. It could not be tested, had no timeouts, and sent the wrong currency field (D4).
   - **New design:**
     - one `_send()` pipeline (token, timeout, decoding, connection errors);
     - `ApiResponse` with `ok`, `errorMessage` and `errorCode`;
     - three result helpers matching how the app consumes results;
     - an injectable `http.Client`.
   - **Kept:** every public signature and result key, so no caller changed.
   - **Results:** duplication 5.14% → 0%; `try` blocks 27 → 6. 14 unit tests with `MockClient`.

A full rewrite fit better than small refactors in both cases. The problem was each class's overall structure (several jobs tangled together in one case, 27 copies of one pipeline in the other), not a few bad methods. Details are in [report 03](03_Rewriting_Report.md).

## 5. Testing and regression

| Suite | Result |
|---|---|
| Backend unit (services, rewritten export, migrator, architecture) | 40/40 |
| Backend integration on real MySQL (migrations, repositories) | 14/14 |
| Backend system workflows over HTTP (15 cases, including **Add Expense** and **Monthly Budget Summary**) | 15/15, line coverage 90.8% |
| Flutter (rewritten ApiService + widget smoke test) | 15/15, `flutter analyze` clean |
| **Regression:** the same 15 workflows against the `a01-baseline` server | 12/15. The 3 failures are exactly the defect tests D1, D2 and D3. **All other Assignment 01 behaviour is unchanged.** |

**Not done:** a manual click-through of the Flutter UI against the new backend, with screenshots ([how to do it](04_Test_Report.md#5-manual-ui-check)).

## 6. Demonstration script

The production dump is not in git (it contains personal data); the Team Lead has the local copy. Steps 1–2 also work with any dump, or without one (`npm run demo`).

| # | Step | Command / action | Shows |
|---|---|---|---|
| 1 | Migration on real data | `cd Backend && node scripts/rehearse-migration.js Database/dump/expensemate_db.sql` | Status before (pending) → snapshot → migrate → verify PASS → re-run no-op |
| 2 | App on the migrated DB | `npm run demo -- Database/dump/expensemate_db.sql`, then `flutter run --dart-define=API_BASE_URL=http://localhost:5000/api` | Add an expense **with a receipt** (failed in Assignment 01) |
| 3 | Trace one operation | Open `transaction.controller.js` → `create` → `TransactionService.create` → `TransactionRepository.create` / `ReceiptRepository.upsert` → `migrations/002` | Controller → Service → Repository → Database |
| 4 | Layering is enforced | `npm run test:unit`, then add `require('../config/db')` to a controller and run again | `architecture.test.js` fails |
| 5 | Rewritten classes | `services/export/` and `api_service.dart` side by side with `git show a01-baseline:<path>`; run `node --test tests/unit/export.test.js` and `flutter test test/services` | Problems solved; tests pass |
| 6 | Regression | `npm run test:regression` (about 1 minute) | Baseline 12/15 (only D1–D3 fail); current 15/15 |

### Challenge, trade-off and lesson for each concept

| | Challenge | Trade-off | Lesson learned |
|---|---|---|---|
| **Migration** | Proving that real records survive without touching production. Solved with a throwaway MySQL and a per-row fingerprint snapshot of the dump | The API keeps returning the full receipt in lists (compatibility over smaller payloads); rollback cannot restore receipts over 500 characters | Rehearse every migration on a copy of real data; record applied versions and checksums instead of relying on `IF NOT EXISTS` |
| **Refactoring** | Splitting rules that were written *inside SQL* (carry-forward, balances) without changing any API response | About 52% more lines and more files; some single queries became 2–3 simpler ones | Write black-box tests *before* moving code. The suite that passed on the old server is what made the refactor safe, and it exposed D2 |
| **Rewriting** | Keeping 27 Flutter methods and every result-map key compatible while replacing their internals | The new ApiService keeps the old untyped `Map` results so no screen changed; typed results would be cleaner but would touch every screen | Freeze the public interface first, then rewrite behind it; tests with a mock client catch contract slips such as D4 |

## 7. Team contribution

> **TO DO (team):** replace the placeholders. Both members must be able to explain all three parts.

| Task | Member | Evidence |
|---|---|---|
| Code review and defect identification (D1–D5) | _[name]_ | Report 04, defect log |
| Part A — migration runner, migration 002, rehearsal | _[name]_ | `d02795f` |
| Configuration/secrets migration | _[name]_ | `51634b9`, `8930c8e` |
| Part B — layered backend (controllers, services, repositories, container) | _[name]_ | `52d3fd8`, `7b3071e` |
| Part C — export module rewrite | _[name]_ | `0714d13` |
| Part C — Flutter ApiService rewrite | _[name]_ | `75ce795` |
| Test suites, regression script, metrics | _[name]_ | `ed3977b`, `Assignment02/metrics` |
| Reports and demo preparation | _[name]_ | `Assignment02/` |

## 8. Known limitations and future work

- **Production:**
  - run migration 002 on the server after a backup;
  - rotate the credentials that were previously committed to git;
  - serve the API over HTTPS.
- **List endpoints** still return full receipt images. Add a `has_receipt` flag and fetch receipts on demand.
- **`ExpenseState`** (715 lines) in Flutter still combines caching, API calls and calculations. It is the next rewrite candidate.
- **Tests run on MySQL 8.0.31**, while production runs 8.0.44.
