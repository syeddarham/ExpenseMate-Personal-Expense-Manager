const express = require('express');

/**
 * Maps URLs to controller handlers. Every module follows
 * Controller -> Service -> Repository -> Database (see src/container.js).
 */
function createRouter({ controllers, requireAuth }) {
  const { auth, users, accounts, categories, transactions, budgets, analytics } = controllers;
  const router = express.Router();

  router.get('/health', (req, res) => {
    res.json({ status: 'ok', name: 'ExpenseMate API', timestamp: new Date().toISOString() });
  });

  // Public
  router.post('/auth/register', auth.register);
  router.post('/auth/verify-email', auth.verifyEmail);
  router.post('/auth/resend-code', auth.resendCode);
  router.post('/auth/login', auth.login);
  router.post('/auth/forgot-password', auth.forgotPassword);
  router.post('/auth/reset-password', auth.resetPassword);

  // Everything below needs a valid token
  router.get('/users/me', requireAuth, users.getMe);
  router.put('/users/me', requireAuth, users.updateMe);
  router.put('/users/me/currency', requireAuth, users.convertCurrency);
  router.put('/users/me/password', requireAuth, users.changePassword);

  router.get('/accounts', requireAuth, accounts.list);
  router.post('/accounts', requireAuth, accounts.create);
  router.put('/accounts/:id', requireAuth, accounts.update);
  router.delete('/accounts/:id', requireAuth, accounts.remove);

  router.get('/categories', requireAuth, categories.list);
  router.post('/categories', requireAuth, categories.create);
  router.put('/categories/:id', requireAuth, categories.update);
  router.delete('/categories/:id', requireAuth, categories.remove);

  router.get('/transactions', requireAuth, transactions.list);
  router.post('/transactions', requireAuth, transactions.create);
  router.post('/transactions/export', requireAuth, transactions.exportAll);
  router.get('/transactions/:id', requireAuth, transactions.get);
  router.put('/transactions/:id', requireAuth, transactions.update);
  router.delete('/transactions/:id', requireAuth, transactions.remove);

  router.get('/budgets', requireAuth, budgets.list);
  router.put('/budgets/:categoryId', requireAuth, budgets.set);

  router.get('/overview', requireAuth, analytics.overview);
  router.get('/analytics', requireAuth, analytics.analytics);

  return router;
}

module.exports = { createRouter };
