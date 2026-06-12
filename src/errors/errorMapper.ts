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
  EmailDeliveryError,
  PasswordResetEmailDeliveryError,
  InvalidEmailVerificationTokenError,
  DatabaseCleanupError,
} from "./appErrors";
import { HttpError } from "./httpErrors";

export type HttpErrorPayload = {
  statusCode: number;
  message: string;
  code: string;
  details?: Record<string, string[]>;
  stack?: string;
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

function mapHttpError(error: HttpError): HttpErrorPayload {
  const payload: HttpErrorPayload = {
    statusCode: error.statusCode,
    message: error.message,
    code: error.code,
  };

  if (error.statusCode === 500 && error.stack) {
    payload.stack = error.stack;
  }

  return payload;
}

function mapAuthError(error: unknown): HttpErrorPayload | null {
  const authErrors = [
    [DuplicateUserError, 409, "DUPLICATE_USER"],
    [InvalidCredentialsError, 401, "INVALID_CREDENTIALS"],
    [MissingAuthTokenError, 401, "MISSING_AUTH_TOKEN"],
    [MalformedAuthorizationHeaderError, 401, "MALFORMED_AUTH_HEADER"],
    [InvalidTokenPayloadError, 401, "INVALID_TOKEN_PAYLOAD"],
    [AuthenticatedUserNotFoundError, 401, "AUTHENTICATED_USER_NOT_FOUND"],
    [UserNotFoundError, 404, "USER_NOT_FOUND"],
    [InvalidOrExpiredResetCodeError, 400, "INVALID_OR_EXPIRED_RESET_CODE"],
    [EmailDeliveryError, 502, "EMAIL_DELIVERY_ERROR"],
    [
      PasswordResetEmailDeliveryError,
      502,
      "PASSWORD_RESET_EMAIL_DELIVERY_ERROR",
    ],
    [
      InvalidEmailVerificationTokenError,
      400,
      "INVALID_EMAIL_VERIFICATION_TOKEN",
    ],
    [DatabaseCleanupError, 500, "DATABASE_CLEANUP_ERROR"],
  ] as const;

  for (const [ErrorClass, statusCode, code] of authErrors) {
    if (error instanceof ErrorClass) {
      return {
        statusCode,
        message: error.message,
        code,
      };
    }
  }

  return null;
}

function mapPrismaError(error: unknown): HttpErrorPayload | null {
  if (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === "P2025"
  ) {
    return {
      statusCode: 404,
      message: "Risorsa non trovata",
      code: "NOT_FOUND",
    };
  }

  return null;
}

export function mapErrorToHttp(error: unknown): HttpErrorPayload {
  if (error instanceof HttpError) {
    return mapHttpError(error);
  }

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

  const authError = mapAuthError(error);
  if (authError) {
    return authError;
  }

  const prismaError = mapPrismaError(error);
  if (prismaError) {
    return prismaError;
  }

  if (error instanceof Error && error.stack) {
    return {
      statusCode: 500,
      message: "Errore interno del server",
      code: "INTERNAL_SERVER_ERROR",
      stack: error.stack,
    };
  }

  return {
    statusCode: 500,
    message: "Errore interno del server",
    code: "INTERNAL_SERVER_ERROR",
  };
}
