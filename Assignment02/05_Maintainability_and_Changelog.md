# Maintainability Comparison and Change Log

## 1. How the measurements were taken

`node Assignment02/metrics/measure.js` checks out tag `a01-baseline` into a temporary git worktree. It then measures the baseline and the current tree **with the same tools and settings** and writes [evidence/metrics.json](evidence/metrics.json).

| Indicator | Tool / method |
|---|---|
| Cyclomatic complexity per function | ESLint 9.39.5, rule `complexity` with threshold 0 (reports every function) |
| Duplicated code | jscpd 4.0.5, minimum clone 50 tokens |
| Dependency separation | Files outside `repositories/`, `database/`, `config/` that contain SQL keywords or import `config/db`. `container.js` (composition root, creates the pool but runs no SQL) is excluded |
| Size | Non-blank lines of `Backend/src/**/*.js`; controller lines separately |
| Test coverage | `node --test --experimental-test-coverage` over all backend tests |
| Repetition in ApiService | Counts of `try {`, `jsonDecode(` and direct `http.get/post/put/delete(` calls |

## 2. Results

### Backend (`Backend/src`)

| Indicator | Assignment 01 | Assignment 02 | Change |
|---|---|---|---|
| Files with SQL / pool access outside the data layer | **11** | **0** | −100% (now enforced by `architecture.test.js`) |
| Average cyclomatic complexity per function | 3.80 | 2.19 | −42% |
| Highest function complexity | 27 (`parseTransactionBody`) | 12 (`Validator.string`, unchanged code) | −56% |
| Functions with complexity > 10 | 6 | 1 | −5 |
| Non-blank lines in controllers | 866 | 355 | −59% |
| Duplicated lines (jscpd) | 18 (0.92%) | 15 (0.51%) | −45% relative |
| Line coverage by automated tests | 0% (no tests) | 90.82% | +90.8 pp |
| Source files / non-blank lines | 28 / 1,735 | 43 / 2,643 | +52% lines (see trade-off) |

### Flutter `ApiService` (rewritten class)

| Indicator | Assignment 01 | Assignment 02 |
|---|---|---|
| Non-blank lines | 598 | 467 (−22%) |
| `try` blocks | 27 | 6 |
| `jsonDecode` calls | 22 | 1 |
| Direct `http.*` calls (untestable) | 27 | 0 (one injectable client) |
| Duplicated code (jscpd) | 5.14% (4 clones) | 0% |
| Unit tests | 0 | 14 |

### Responsibilities (by inspection)

- **Assignment 01:** a controller did 4 jobs: validation, business rules, SQL and JSON formatting. `export.service.js` also did 4: SQL, CSV, PDF and e-mail.
- **Assignment 02:** each controller, service, repository and renderer has a single job (see the layer table in report 02).

## 3. Interpretation

- **Separation, complexity and testability improved clearly.**
  - The most complex function (27) was split across a controller (shape checks) and a service (resolution rules).
  - Business rules are now unit-tested without a database.
- **Total size grew by 52%. This is a deliberate trade-off, not an improvement.** The growth comes from:
  - one file per layer and module;
  - doc comments on every class;
  - explicit dependency wiring in `container.js`.
- **Duplication was already low in the backend.** The large duplication win is in the Flutter `ApiService`.

---

## 4. Change log

Baseline: tag `a01-baseline` = `59c3c27`. All work is on branch `assignment-02`.

| Commit | Concept | Files / classes affected | Reason |
|---|---|---|---|
| `51634b9` | Migration (config) | `Backend/.env`, `Backend/Database/dump/` untracked | Credentials and personal data were committed to git |
| `8930c8e` | Migration (config) + clean-up | `.gitignore`, `.env.example`, `api_service.dart` (`API_BASE_URL`), `main.dart`, `constants.dart` + 27 widget files (design tokens), `login_page.dart` removed, docs | Secrets and endpoint moved out of source code; hard-coded style values; duplicate login page |
| `d02795f` | **Migration (A)** | `Database/migrations/001…, 002…`, `src/database/migrator.js`, `scripts/migrate.js`, `verify-migration.js`, `rehearse-migration.js`; `schema.sql` and `initDb.js` removed | Versioned, repeatable schema changes; D1 (receipts did not fit `VARCHAR(500)`) |
| `0714d13` | **Rewrite (C)** | `services/export/{statement,csv.renderer,pdf.renderer,export.service}.js`; old `export.service.js` replaced | 4 responsibilities in one module; D3 (empty account column, crash on tags) |
| `52d3fd8` | **Refactoring (B)** | `controllers/*` (7), new `services/*` (9), `repositories/*` (7), `database/database.js`, `container.js`, `app.js`, `server.js`, `routes/index.js` (7 route files merged), `middleware/auth.js`, `utils/http.js`, `utils/serializers.js`; `services/codes.js` → `VerificationCodeService` | Controller → Service → Repository → Database; D2 (dashboard budget double-counted) |
| `ed3977b` | Testing | `tests/system/*`, `scripts/run-regression.sh` | Same system suite runs against baseline and current code |
| `75ce795` | **Rewrite (C)** | `Frontend/lib/services/api_service.dart`, `Frontend/test/services/api_service_test.dart` | 27 duplicated request pipelines, untestable, no timeouts; D4 (currency not saved) |
| `7b3071e` | Refactoring (B) | `controllers/user.controller.js`, `tests/system/workflows.test.js` (ST-15) | `updateMe` complexity 16 → table-driven |
| `5e4dd12` | Demo support | `scripts/demo-server.js`, `package.json` | Live demo without touching the production database |
| *docs commit* | Documentation | `Assignment02/*`, `ProjectDescription.md`, `AGENTS.md` | Reports, evidence, metrics; docs updated to the new structure |
