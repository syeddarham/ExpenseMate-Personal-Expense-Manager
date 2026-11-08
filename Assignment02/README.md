# ExpenseMate — Assignment 02: Software Evolution

Migration, refactoring and rewriting of the Assignment 01 ExpenseMate system.

| Item | Location |
|---|---|
| Assignment 01 baseline | git tag `a01-baseline` (commit `59c3c27`) |
| Assignment 02 work | git branch `assignment-02` |
| Final report (3–4 pages) | [06_Final_Report.md](06_Final_Report.md) |
| Migration report | [01_Migration_Report.md](01_Migration_Report.md) |
| Refactoring report | [02_Refactoring_Report.md](02_Refactoring_Report.md) |
| Rewriting report | [03_Rewriting_Report.md](03_Rewriting_Report.md) |
| Test package (cases, results, regression, defect log) | [04_Test_Report.md](04_Test_Report.md) |
| Maintainability comparison + change log | [05_Maintainability_and_Changelog.md](05_Maintainability_and_Changelog.md) |
| Raw evidence (test logs, coverage, metrics, migration rehearsal) | [evidence/](evidence/) |
| Metrics script | [metrics/measure.js](metrics/measure.js) |

## Reproducing everything

Requirements: Node.js 18+ (tested on 24.21), Flutter 3.27+. **No MySQL installation is needed**:
the tests start a throwaway MySQL 8.0.31 server (`mysql-memory-server`, downloaded once, about 1 minute).

```bash
cd Backend && npm install
npm test                                     # 69 unit + integration + system tests
npm run test:coverage                        # same, with a coverage table
npm run test:regression                      # same system tests vs a01-baseline and current code
node scripts/rehearse-migration.js <dump.sql>   # migration rehearsal on a copy of real data
npm run demo                                 # API on http://localhost:5000/api for the live demo

cd ../Frontend && flutter test               # 15 Flutter tests
flutter run --dart-define=API_BASE_URL=http://localhost:5000/api   # app against the demo API

cd .. && node Assignment02/metrics/measure.js   # before/after metrics
```

## Building the submission ZIP

Create the ZIP from git, **not** by compressing the project folder. The folder also contains `Backend/.env` (real credentials), `Backend/Database/dump/` (real users' data) and `node_modules/`. None of these is tracked, so `git archive` leaves them out:

```bash
git archive --format=zip --prefix=ExpenseMate/ -o ExpenseMate_Assignment02.zip assignment-02
```

## Status of the requirements

| Requirement | Status |
|---|---|
| Part A — migration with procedure, risks and verification | Done (versioned migrations + receipts table; config/secrets migration) |
| Part B — Controller → Service → Repository → Database for ≥ 2 features | Done for all 7 backend modules |
| Part C — ≥ 2 classes rewritten with unit tests | Done (backend export module, Flutter `ApiService`) |
| Unit tests + ≥ 5 integration/system test cases | Done (69 backend + 15 Flutter tests; 15 system workflows) |
| Regression evidence against Assignment 01 | Done (same suite run against `a01-baseline`) |
| Change log, before/after metrics | Done |
| Git: baseline tag + separate branch | Done |
| **Team contribution table** | **TO DO — fill in member names and tasks in [06_Final_Report.md](06_Final_Report.md#7-team-contribution)** |
| **Screenshots of the Flutter app running on the new backend** | **TO DO — not captured yet (see [04_Test_Report.md](04_Test_Report.md#5-manual-ui-check))** |
| **Running migration 002 on the production server** | **Not done (rehearsed on a copy only; procedure in the migration report)** |
| Live demonstration | Prepared — script in [06_Final_Report.md](06_Final_Report.md#6-demonstration-script) |
