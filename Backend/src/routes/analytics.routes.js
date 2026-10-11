const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

router.get('/overview', analyticsController.getOverview);
router.get('/analytics', analyticsController.getAnalytics);

module.exports = router;
