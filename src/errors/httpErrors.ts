export class HttpError extends Error {
  statusCode: number;
  code: string;

  constructor(statusCode: number, message: string, code?: string) {
    super(message);
    this.statusCode = statusCode;
    this.code = code ?? "GENERIC_ERROR";
  }
}

export class ForbiddenError extends HttpError {
  constructor(message = "Operazione non consentita") {
    super(403, message, "FORBIDDEN");
  }
}

export class ConflictError extends HttpError {
  constructor(message = "Conflitto") {
    super(409, message, "CONFLICT");
  }
}

export class NotFoundError extends HttpError {
  constructor(message = "Risorsa non trovata") {
    super(404, message, "NOT_FOUND");
  }
}
