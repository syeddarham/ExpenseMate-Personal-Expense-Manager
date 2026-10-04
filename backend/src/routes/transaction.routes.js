const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transaction.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

router.get('/', transactionController.listTransactions);
router.post('/', transactionController.createTransaction);
router.get('/:id', transactionController.getTransaction);
router.put('/:id', transactionController.updateTransaction);
router.delete('/:id', transactionController.deleteTransaction);

module.exports = router;
