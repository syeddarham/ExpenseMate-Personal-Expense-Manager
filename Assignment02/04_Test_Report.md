# Test Package — Unit, Integration, System and Regression Tests

Every number below comes from an actual run on 8 November 2026. The raw output is in [evidence/](evidence/).

## 1. Test environment

| Item | Value |
|---|---|
| Backend runner | `node --test` (Node.js 24.21.0), no extra test framework |
| Database for tests | Throwaway MySQL **8.0.31** started per test file by `mysql-memory-server` (production is 8.0.44; 8.0.31 is the newest build that runs on macOS 12). Never the real server. |
| E-mail | Fake mailer in-process; when the server runs as a child process, OTP codes are read from its console output (the mailer prints them when SMTP is not configured) |
| Flutter | `flutter test` with `package:http/testing` `MockClient` |

## 2. Summary of results

| Suite | Command | Tests | Result |
|---|---|---|---|
| Backend unit | `npm run test:unit` | 40 | 40 pass |
| Backend integration (real MySQL) | `npm run test:integration` | 14 | 14 pass |
| Backend system (HTTP workflows) | `npm run test:system` | 15 | 15 pass |
| **Backend total + coverage** | `npm run test:coverage` | **69** | **69 pass; 90.82% lines, 82.42% branches, 93.68% functions** ([log](evidence/backend-tests-and-coverage.txt)) |
| Flutter | `flutter test --concurrency=1` | 15 | 15 pass; `flutter analyze`: no issues ([log](evidence/frontend-tests.txt)) |
| **Regression vs Assignment 01** | `npm run test:regression` | 15 + 15 | Baseline **12/15**; Assignment 02 **15/15** ([baseline](evidence/regression-baseline.txt), [current](evidence/regression-current.txt)) |

Assignment 01 had no backend tests and one Flutter smoke test.

## 3. Unit tests (changed services, repositories and rewritten classes)

| File | Tests | What it checks |
|---|---|---|
| `tests/unit/budget.service.test.js` | 6 | Carry-forward rule, monthly summary, total budget without double counting (D2), income categories rejected |
| `tests/unit/transaction.service.test.js` | 8 | Category/account resolution order (id → name → first; auto-creates "Cash"), receipt written inside the same DB transaction, PUT removes an omitted receipt, 404s |
| `tests/unit/analytics.service.test.js` | 3 | Percentages to 1 decimal place, `[start, end)` bucket boundaries, balance formula |
| `tests/unit/account.service.test.js` | 3 | Balance rounding, default accounts created once, other users' accounts → 404 |
| `tests/unit/verificationCode.service.test.js` | 4 | Code stored as a hash only, 30 s cooldown, attempt counting, expired/locked/missing codes |
| `tests/unit/export.test.js` | 8 | **Rewritten export:** tag parsing, cent-exact totals, CSV escaping + formula guard, account column (D3), multi-page PDF, response shape, e-mail, format fallback |
| `tests/unit/migrator.test.js` | 4 | Migration file pairing/sorting, missing `.up.sql`, checksum line endings |
| `tests/unit/architecture.test.js` | 4 | Dependency direction Controller → Service → Repository; no SQL outside repositories |
| `Frontend/test/services/api_service_test.dart` | 14 | **Rewritten ApiService:** URL handling, token storage and header, error mapping, `needsVerification`, offline fallbacks, query parameters, D4 payload, export mapping |

## 4. Integration and system test cases

**Integration (real MySQL):**
- `tests/integration/migrations.test.js` (5): fresh install, data preservation with verification, D1 on old vs new schema, rollback/re-apply, checksum drift.
- `tests/integration/repositories.test.js` (9): joins, row ownership, cascade delete of receipts, filters, raw totals, name lookup, budget history, column whitelist, transaction rollback.

**System workflows** (`tests/system/workflows.test.js`). These are black-box HTTP calls made the same way the Flutter app makes them. Each case registers its own user.

| ID | Workflow (Assignment 01 feature) | Key checks | A01 | A02 |
|---|---|---|---|---|
| ST-01 | Register → e-mail code → verify → login → profile | wrong code 400; 5 default accounts | ✔ | ✔ |
| ST-02 | Access control | unverified login 403 `EMAIL_NOT_VERIFIED`; no/invalid token 401 | ✔ | ✔ |
| ST-03 | Forgot → reset password → login | old password 401, new 200 | ✔ | ✔ |
| ST-04 | **Add expense + income** | listed, filtered by type; account balances; dashboard totals | ✔ | ✔ |
| ST-05 | Edit and delete a transaction | amount updated; 404 after delete; balance back to 0 | ✔ | ✔ |
| ST-06 | **Monthly budget summary** | limit + spent; carry-forward to next month; income category 404 | ✔ | ✔ |
| ST-07 | [D2] Dashboard total budget after a limit change | 350 + 100 = 450 | ✖ (650) | ✔ |
| ST-08 | Category management | duplicate 400; in-use delete 400; unused delete 200 | ✔ | ✔ |
| ST-09 | Analytics (month) | breakdown 83.3% / 16.7%; trend sums to total | ✔ | ✔ |
| ST-10 | Export CSV without e-mail | header, record count, base64 file | ✔ | ✔ |
| ST-11 | [D3] Export with account names and tags | account column filled; tagged row exported | ✖ (500) | ✔ |
| ST-12 | [D1] Attach a photographed receipt (~150 KB) | saved (201) and returned unchanged | ✖ (500) | ✔ |
| ST-13 | Currency conversion | amounts and budget limits × rate; code upper-cased | ✔ | ✔ |
| ST-14 | Accounts | create, rename, delete; another user gets 404 | ✔ | ✔ |
| ST-15 | Profile and password | preferences saved; taken e-mail 409; bad name 400; password change | ✔ | ✔ |

### Regression testing method

`scripts/run-regression.sh` does the following:
1. Checks out tag `a01-baseline` into a temporary git worktree and deletes the old tracked `.env` there.
2. Starts that version's own `server.js` on a fresh MySQL and runs the 15 workflows above.
3. Does the same for the current code, also through `server.js`, which exercises the migrations at startup.

The **only** failures on Assignment 01 are the three tests written for defects found during this assignment. **All 12 other Assignment 01 workflows behave identically before and after the changes.**

## 5. Manual UI check

**Not done yet (marked TO DO).** The UI code changed only in `api_service.dart`. Its public interface is unchanged, `flutter analyze` is clean and the widget smoke test passes, but no one has yet clicked through the app against the new backend. To do it and capture screenshots for the submission:

```bash
cd Backend && npm run demo -- Database/dump/expensemate_db.sql   # or without the dump
cd Frontend && flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
```

Suggested screenshots: sign-up + OTP (code shown in the demo terminal), add an expense **with a scanned receipt**, Budgets screen, Home dashboard, Profile → Export CSV.

## 6. Defect log

| ID | Found by | Defect (Assignment 01) | Fix | Verified by |
|---|---|---|---|---|
| D1 | Code review + ST-12 | Receipts are base64 images but `receipt_url` was `VARCHAR(500)`, so any receipt upload returned 500 `ER_DATA_TOO_LONG` | Migration 002 (`transaction_receipts`, MEDIUMTEXT) | ST-12; `migrations.test.js` |
| D2 | Code review + ST-07 | Dashboard `total_budget` summed all historical limits (650 instead of 450) | `BudgetService.totalBudgetForMonth` reuses carry-forward | ST-07; `budget.service.test.js` |
| D3 | Code review + ST-11 | Export: Account column always empty; tagged transactions crashed the export (500) | Export module rewrite | ST-11; `export.test.js` |
| D4 | Code review | Flutter `updateMe` sent `currency_code`; API expects `preferred_currency`, so the selected currency was never saved | ApiService rewrite | `api_service_test.dart` (D4 test) |
| D5 | Code review | `PUT /users/me/currency` without `currency_code` threw a TypeError (500) instead of 400 | Validation before use in `UserController` | **Not covered by an automated test** |
| T1 | Test development | Node 24 `node --test <folder>` no longer finds files | npm scripts use glob patterns | All suites run |
| T2 | Metrics | ESLint 9 ignores files outside its working directory (empty report) | Metrics script runs ESLint inside each `src/` | `metrics.json` |
