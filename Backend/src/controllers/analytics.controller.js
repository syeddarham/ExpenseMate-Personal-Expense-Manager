const { asyncHandler } = require('../utils/http');
const { overviewToJson, analyticsToJson } = require('../utils/serializers');

/** HTTP layer for /api/overview and /api/analytics. */
function createAnalyticsController({ analyticsService }) {
  return {
    overview: asyncHandler(async (req, res) => {
      res.json(overviewToJson(await analyticsService.overview(req.user.id)));
    }),

    /** GET /api/analytics?period=day|week|month|year */
    analytics: asyncHandler(async (req, res) => {
      const period = req.query.period || 'month';
      res.json(analyticsToJson(await analyticsService.analytics(req.user.id, period)));
    }),
  };
}

module.exports = { createAnalyticsController };
