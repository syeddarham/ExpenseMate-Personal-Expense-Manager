/**
 * Error carrying an HTTP status code and a machine-readable code.
 * Services throw the subclasses below; the error middleware maps them to
 * JSON responses, so services never touch `res`.
 */
class HttpError extends Error {
  constructor(status, message, code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

class ValidationError extends HttpError {
  constructor(message, code = 'VALIDATION_ERROR') {
    super(400, message, code);
  }
}

class UnauthorizedError extends HttpError {
  constructor(message, code = 'UNAUTHENTICATED') {
    super(401, message, code);
  }
}

class ForbiddenError extends HttpError {
  constructor(message, code = 'FORBIDDEN') {
    super(403, message, code);
  }
}

class NotFoundError extends HttpError {
  constructor(message, code = 'NOT_FOUND') {
    super(404, message, code);
  }
}

class ConflictError extends HttpError {
  constructor(message, code = 'CONFLICT') {
    super(409, message, code);
  }
}

class TooManyRequestsError extends HttpError {
  constructor(message, code = 'TOO_MANY_REQUESTS') {
    super(429, message, code);
  }
}

/** Wraps async route handlers so rejected promises reach the error middleware. */
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = {
  HttpError,
  ValidationError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  TooManyRequestsError,
  asyncHandler,
};
