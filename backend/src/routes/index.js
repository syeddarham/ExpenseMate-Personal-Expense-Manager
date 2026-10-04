const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const accountRoutes = require('./account.routes');
const categoryRoutes = require('./category.routes');
const transactionRoutes = require('./transaction.routes');
const budgetRoutes = require('./budget.routes');
const analyticsRoutes = require('./analytics.routes');

// Health check
router.get('/health', (req, res) => {
  res.json({ status: 'ok', name: 'ExpenseMate API', timestamp: new Date().toISOString() });
});

// Mounted modules
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/accounts', accountRoutes);
router.use('/categories', categoryRoutes);
router.use('/transactions', transactionRoutes);
router.use('/budgets', budgetRoutes);
router.use('/', analyticsRoutes); // provides /overview and /analytics

module.exports = router;
