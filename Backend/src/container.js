/**
 * Composition root: builds every layer once and wires the dependencies
 * in one direction only:
 *
 *   Controller -> Service -> Repository -> Database (mysql2 pool)
 *
 * Tests pass their own `pool`, `mailer` or `env` to get an isolated app.
 */
const defaultEnv = require('./config/env');
const { createPool } = require('./config/db');
const { Database } = require('./database/database');
const defaultMailer = require('./services/mailer');

const { UserRepository } = require('./repositories/user.repository');
const { VerificationCodeRepository } = require('./repositories/verificationCode.repository');
const { AccountRepository } = require('./repositories/account.repository');
const { CategoryRepository } = require('./repositories/category.repository');
const { TransactionRepository } = require('./repositories/transaction.repository');
const { ReceiptRepository } = require('./repositories/receipt.repository');
const { BudgetRepository } = require('./repositories/budget.repository');

const { TokenService } = require('./services/token.service');
const { VerificationCodeService } = require('./services/verificationCode.service');
const { AuthService } = require('./services/auth.service');
const { UserService } = require('./services/user.service');
const { AccountService } = require('./services/account.service');
const { CategoryService } = require('./services/category.service');
const { TransactionService } = require('./services/transaction.service');
const { BudgetService } = require('./services/budget.service');
const { AnalyticsService } = require('./services/analytics.service');
const { ExportService } = require('./services/export/export.service');

const { createAuthController } = require('./controllers/auth.controller');
const { createUserController } = require('./controllers/user.controller');
const { createAccountController } = require('./controllers/account.controller');
const { createCategoryController } = require('./controllers/category.controller');
const { createTransactionController } = require('./controllers/transaction.controller');
const { createBudgetController } = require('./controllers/budget.controller');
const { createAnalyticsController } = require('./controllers/analytics.controller');
const { createRequireAuth } = require('./middleware/auth');

function buildContainer({ env = defaultEnv, pool = createPool(env.db), mailer = defaultMailer } = {}) {
  // Database
  const db = new Database(pool);

  // Repositories
  const userRepository = new UserRepository(db);
  const codeRepository = new VerificationCodeRepository(db);
  const accountRepository = new AccountRepository(db);
  const categoryRepository = new CategoryRepository(db);
  const transactionRepository = new TransactionRepository(db);
  const receiptRepository = new ReceiptRepository(db);
  const budgetRepository = new BudgetRepository(db);

  // Services
  const tokenService = new TokenService(env.jwt);
  const codeService = new VerificationCodeService({ codeRepository, mailer });
  const accountService = new AccountService({ accountRepository });
  const categoryService = new CategoryService({ categoryRepository, transactionRepository });
  const authService = new AuthService({ db, userRepository, accountService, categoryService, codeService, tokenService });
  const userService = new UserService({ db, userRepository, accountRepository, transactionRepository, budgetRepository });
  const transactionService = new TransactionService({
    db,
    transactionRepository,
    receiptRepository,
    categoryRepository,
    accountRepository,
  });
  const budgetService = new BudgetService({ budgetRepository, categoryRepository, transactionRepository });
  const analyticsService = new AnalyticsService({ accountRepository, transactionRepository, budgetService });
  const exportService = new ExportService({ userRepository, transactionRepository, mailer });

  // Controllers
  const controllers = {
    auth: createAuthController({ authService }),
    users: createUserController({ userService }),
    accounts: createAccountController({ accountService }),
    categories: createCategoryController({ categoryService }),
    transactions: createTransactionController({ transactionService, exportService }),
    budgets: createBudgetController({ budgetService }),
    analytics: createAnalyticsController({ analyticsService }),
  };

  return {
    env,
    pool,
    db,
    services: { authService, userService, accountService, categoryService, transactionService, budgetService, analyticsService, exportService },
    controllers,
    requireAuth: createRequireAuth({ authService }),
  };
}

module.exports = { buildContainer };
