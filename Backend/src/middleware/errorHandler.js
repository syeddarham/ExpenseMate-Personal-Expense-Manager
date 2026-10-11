const env = require('../config/env');

function notFound(req, res) {
  res.status(404).json({ error: { message: `Route not found: ${req.method} ${req.originalUrl}`, code: 'NOT_FOUND' } });
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, _req, res, _next) {
  let status = err.status || 500;
  let message = err.message || 'Internal server error';
  let code = err.code;

  // Translate common MySQL errors into friendly API errors
  if (err.code === 'ER_DUP_ENTRY') {
    status = 409;
    message = 'A record with the same unique value already exists';
    code = 'DUPLICATE';
  } else if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    status = 409;
    message = 'This item is still in use and cannot be deleted';
    code = 'IN_USE';
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'Malformed JSON body';
    code = 'BAD_JSON';
  }

  if (status >= 500) {
    console.error(err);
    if (env.nodeEnv === 'production') message = 'Internal server error';
  }

  const body = { error: { message, code: typeof code === 'string' ? code : undefined } };
  if (err.details) body.error.details = err.details;
  res.status(status).json(body);
}

module.exports = { notFound, errorHandler };
