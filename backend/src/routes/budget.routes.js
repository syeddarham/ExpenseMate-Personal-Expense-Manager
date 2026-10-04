const express = require('express');
const router = express.Router();
const budgetController = require('../controllers/budget.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

router.get('/', budgetController.listBudgets);
router.put('/:categoryId', budgetController.setBudget);

module.exports = router;
