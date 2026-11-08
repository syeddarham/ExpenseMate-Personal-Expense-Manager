const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { createRouter } = require('./routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

/** Builds the Express app around an already-wired container (see container.js). */
function createApp(container) {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: true, credentials: true }));
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
  }

  app.use('/api', createRouter(container));
  app.use(notFound);
  app.use(errorHandler(container.env));

  return app;
}

module.exports = { createApp };
