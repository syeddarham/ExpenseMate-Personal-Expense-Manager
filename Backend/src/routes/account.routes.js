const express = require('express');
const router = express.Router();
const accountController = require('../controllers/account.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

router.get('/', accountController.listAccounts);
router.post('/', accountController.createAccount);
router.put('/:id', accountController.updateAccount);
router.delete('/:id', accountController.deleteAccount);

module.exports = router;
