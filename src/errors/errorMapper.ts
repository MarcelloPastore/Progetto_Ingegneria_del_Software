import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { JsonWebTokenError, TokenExpiredError } from "jsonwebtoken";
import {
  DuplicateUserError,
  AuthenticatedUserNotFoundError,
  InvalidCredentialsError,
  MissingAuthTokenError,
  MalformedAuthorizationHeaderError,
  InvalidTokenPayloadError,
  UserNotFoundError,
  InvalidOrExpiredResetCodeError,
} from "./appErrors";

export type HttpErrorPayload = {
  statusCode: number;
  message: string;
  code: string;
  details?: Record<string, string[]>;
};

const toValidationDetails = (issues: ZodError["issues"]) => {
  const details = new Map<string, string[]>();

  issues.forEach((issue) => {
    const path = issue.path.length ? issue.path.join(".") : "body";
    const current = details.get(path) ?? [];
    current.push(issue.message);
    details.set(path, current);
  });

  return Object.fromEntries(details);
};

export function mapErrorToHttp(error: unknown): HttpErrorPayload {
  if (error instanceof ZodError) {
    return {
      statusCode: 400,
      message: "Dati non validi",
      code: "BAD_REQUEST",
      details: toValidationDetails(error.issues),
    };
  }

  if (error instanceof TokenExpiredError) {
    return {
      statusCode: 401,
      message: "Token scaduto",
      code: "TOKEN_EXPIRED",
    };
  }

  if (error instanceof JsonWebTokenError) {
    return {
      statusCode: 401,
      message: "Token non valido",
      code: "INVALID_TOKEN",
    };
  }

  if (error instanceof DuplicateUserError) {
    return {
      statusCode: 409,
      message: error.message,
      code: "DUPLICATE_USER",
    };
  }

  if (error instanceof InvalidCredentialsError) {
    return {
      statusCode: 401,
      message: error.message,
      code: "INVALID_CREDENTIALS",
    };
  }

  if (error instanceof MissingAuthTokenError) {
    return {
      statusCode: 401,
      message: error.message,
      code: "MISSING_AUTH_TOKEN",
    };
  }

  if (error instanceof MalformedAuthorizationHeaderError) {
    return {
      statusCode: 401,
      message: error.message,
      code: "MALFORMED_AUTH_HEADER",
    };
  }

  if (error instanceof InvalidTokenPayloadError) {
    return {
      statusCode: 401,
      message: error.message,
      code: "INVALID_TOKEN_PAYLOAD",
    };
  }

  if (error instanceof AuthenticatedUserNotFoundError) {
    return {
      statusCode: 401,
      message: error.message,
      code: "AUTHENTICATED_USER_NOT_FOUND",
    };
  }

  if (error instanceof UserNotFoundError) {
    return {
      statusCode: 404,
      message: error.message,
      code: "USER_NOT_FOUND",
    };
  }

  if (error instanceof InvalidOrExpiredResetCodeError) {
    return {
      statusCode: 400,
      message: error.message,
      code: "INVALID_OR_EXPIRED_RESET_CODE",
    };
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === "P2025") {
      return {
        statusCode: 404,
        message: "Risorsa non trovata",
        code: "NOT_FOUND",
      };
    }
  }

  return {
    statusCode: 500,
    message: "Errore interno del server",
    code: "INTERNAL_SERVER_ERROR",
  };
}
