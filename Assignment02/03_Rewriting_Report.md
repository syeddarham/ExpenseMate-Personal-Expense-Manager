# Part C — Rewriting Report

Two modules were rewritten from scratch. Their required behaviour and their integration with the rest of ExpenseMate are preserved, and each has new unit tests.

## 1. Backend export module (`services/export.service.js` → `services/export/`)

**Commit:** `0714d13` · **Tests:** `Backend/tests/unit/export.test.js` (8 tests) and system tests ST-10 and ST-11.

### Old responsibility and problems

One 169-line module did four jobs: it queried MySQL, built CSV text, drew the PDF with pdfkit, and e-mailed the file.

- **Defect D3a:** the CSV and PDF read `t.account.name`, but `account` is a plain string in the transaction JSON. The *Account* column was **always empty**.
- **Defect D3b:** the CSV called `t.tags.join(', ')`, but `tags` is a comma-separated string. Exporting any user with a tagged transaction **crashed with HTTP 500** (confirmed on the baseline: ST-11 returns `500`).
- **Duplication:** CSV escaping was repeated per column; income/expense totals were computed separately in the PDF code with floating-point sums.
- **Hard-coded layout:** the PDF function contained about 80 numeric literals (positions, widths, font sizes) and 15 hex colours inline.
- **Untestable:** the module imported the global pool directly, so even CSV formatting could not be tested without a database.

### New design

```
ExportService (export.service.js)   coordinates only: load -> statement -> render -> e-mail
  ├── buildStatement() (statement.js)   rows -> { owner, lines[], totals (computed in cents) }
  ├── renderCsv()      (csv.renderer.js) RFC 4180 escaping in one function + CSV-injection guard
  └── renderPdf()      (pdf.renderer.js) layout constants + column table; header/rows/summary functions
```

- **Dependencies are injected:** `userRepository`, `transactionRepository`, `mailer`, and a `clock` (so filenames can be tested).
- **Formats are a strategy map** `{ csv, pdf }`. Adding XLSX would mean adding one entry.

### Why a rewrite instead of a small refactor

- Fixing the two bugs alone would have left the four responsibilities tangled, and the PDF code untestable.
- The data shape every renderer needed (a *statement*) did not exist. Introducing it changes every line that reads transaction fields, which is effectively a rewrite.

### Behaviour preserved / intentional changes

| Kept | Changed on purpose |
|---|---|
| Endpoint, request and response shape (`success, format, filename, email, emailSent, recordCount, base64`) | Account column is filled in (D3a); tags work (D3b) |
| CSV header and column order; PDF layout, colours, totals | Text cells starting with `= + - @` get a leading `'` (prevents spreadsheet formula injection) |
| Unknown format falls back to CSV | Unknown user returns 404 instead of an untyped 500 |

## 2. Flutter `ApiService` (`Frontend/lib/services/api_service.dart`)

**Commit:** `75ce795` · **Tests:** `Frontend/test/services/api_service_test.dart` (14 tests, `package:http/testing` `MockClient`).

### Old responsibility and problems

- **Heavy duplication:** 27 static methods (598 non-blank lines). Each one repeated the same steps: `try`, an `http.get/post/put/delete` call, header map, `jsonDecode`, status check, and digging out `body['error']?['message']`. Measured: 27 `try` blocks, 22 `jsonDecode` calls, 27 direct `http.*` calls, and 5.14% duplicated code (jscpd).
- **Untestable:** the global `http` functions were hard-wired, so no test could run without a live server.
- **No timeout** on any call except health. A hung connection kept a spinner on screen forever.
- **Inconsistent error handling:** some methods returned `error` and some didn't; success checks varied (`== 200`, `== 201`, `201 || 200`).
- **Defect D4:** `updateMe(currencyCode: …)` sent `currency_code`, but the API reads `preferred_currency`. The currency chosen on the *Select Currency* screen and in settings was **silently not saved** (only the symbol was).

### New design

- **`_send(method, path, {body, query, timeout})`:** the single request pipeline. It builds the URL, adds JSON headers and the bearer token, applies a 60 s timeout, decodes JSON once (tolerating HTML error pages), and turns connection failures into `ApiConnectionException`.
- **`ApiResponse`:** exposes `ok`, `errorMessage` and `errorCode` once, instead of 27 inline lookups.
- **Three result helpers**, matching the three styles the app already relied on:
  - `_fetch` returns the data, or a fallback (empty list, default categories, `null`) when anything fails;
  - `_outcome` returns the `{success, message, error, …}` maps used by forms;
  - `_signIn` handles the shared token + user logic of login and e-mail verification.
- **Injectable `http.Client`** (`ApiService.httpClient = MockClient(...)`) for tests.

### Why a rewrite instead of a small refactor

The problem was the *shape* of the class: 27 copies of the same pipeline. Extracting a helper method by method would still have needed every method rewritten against the new pipeline, and the error/fallback rules had to be decided once and for all. A full rewrite with the public API frozen was the cleaner path.

### Behaviour preserved / intentional changes

- **Kept:**
  - every public method name, parameter and return type;
  - every result-map key the screens read (`success`, `error`, `message`, `needsVerification`, `debug_code`, `emailSent`, `recordCount`, …);
  - offline fallbacks.
  - As a result, `AuthService`, `ExpenseState` and all pages compile and work **without edits**. `flutter analyze` reports no issues, and the existing widget test passes.
- **Changed on purpose:**
  - D4 fixed;
  - 60 s request timeout;
  - any 2xx now counts as success (the API only returns 200/201);
  - failed form calls now always include an `error` message.

## 3. Results

| Measure | Export module (before → after) | Flutter ApiService (before → after) |
|---|---|---|
| Responsibilities per file | 4 → 1 | — |
| Defects fixed | D3a, D3b | D4 |
| Duplicated code (jscpd) | part of backend total 0.92% → 0.51% | 5.14% → **0%** |
| `try` blocks / `jsonDecode` / direct `http.*` calls | — | 27/22/27 → **6/1/0** |
| Non-blank lines | 145 → 263 across 4 files (layout tables, doc comments) | 598 → **467** |
| Unit tests | 0 → 8 | 0 → 14 |
