import { describe, it, expect, vi, beforeEach } from "vitest";
import { Ruolo } from "@prisma/client";
import { ZodError, z } from "zod";
import { JsonWebTokenError, TokenExpiredError } from "jsonwebtoken";

const mocks = vi.hoisted(() => ({
  prisma: {
    utente: {
      findUnique: vi.fn(),
    },
  },
  sendErrorReply: vi.fn(),
  sendMail: vi.fn(),
  verifyTransport: vi.fn(),
  createTransport: vi.fn(),
}));

vi.mock("../../src/config/db", () => ({
  prisma: mocks.prisma,
}));

vi.mock("../../src/utils/errorReply", () => ({
  sendErrorReply: mocks.sendErrorReply,
}));

vi.mock("../../src/config/env", () => ({
  env: {
    APP_PUBLIC_URL: "https://coincasa.example.test",
    MAIL_FROM: "noreply@example.test",
    MAIL_FROM_EMAIL: "team@example.test",
    MAIL_FROM_NAME: "CoinCasa",
    MAIL_HOST: "smtp.example.test",
    MAIL_PASSWORD: "secret",
    MAIL_PORT: 465,
    MAIL_SECURE: false,
    MAIL_USER: "mailer",
  },
}));

vi.mock("nodemailer", () => ({
  createTransport: mocks.createTransport,
}));

import { authMiddleware } from "../../src/middleware/AuthMiddleware";
import { requireRole } from "../../src/middleware/RoleMiddleware";
import { mapErrorToHttp } from "../../src/errors/errorMapper";
import {
  AuthenticatedUserNotFoundError,
  DatabaseCleanupError,
  DuplicateUserError,
  EmailDeliveryError,
  InvalidCredentialsError,
  InvalidEmailVerificationTokenError,
  InvalidOrExpiredResetCodeError,
  InvalidTokenPayloadError,
  MalformedAuthorizationHeaderError,
  MissingAuthTokenError,
  PasswordResetEmailDeliveryError,
  UserNotFoundError,
} from "../../src/errors/appErrors";
import { ForbiddenError, HttpError } from "../../src/errors/httpErrors";
import {
  sendPasswordResetEmail,
  sendVerificationEmail,
} from "../../src/utils/mail";

function makeReply() {
  return { status: vi.fn(), send: vi.fn() } as any;
}

describe("Middleware coverage", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("authMiddleware attaches authenticated user from a valid access token", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({ id: "u1" });
    const req = {
      headers: { authorization: "Bearer token" },
      server: {
        jwt: {
          verify: vi.fn(() => ({
            idUtente: "u1",
            idCasa: "c1",
            ruoloCasa: "HomeAdmin",
            type: "access",
          })),
        },
      },
    } as any;

    await authMiddleware(req, makeReply());

    expect(mocks.prisma.utente.findUnique).toHaveBeenCalledWith({
      where: { id: "u1" },
      select: { id: true },
    });
    expect(req.user).toEqual({
      idUtente: "u1",
      idCasa: "c1",
      ruoloCasa: Ruolo.HomeAdmin,
    });
    expect(mocks.sendErrorReply).not.toHaveBeenCalled();
  });

  it("authMiddleware reports malformed auth input and missing users", async () => {
    await authMiddleware(
      { headers: {}, server: { jwt: { verify: vi.fn() } } } as any,
      makeReply(),
    );
    expect(mocks.sendErrorReply.mock.calls.at(-1)?.[1]).toBeInstanceOf(
      MissingAuthTokenError,
    );

    await authMiddleware(
      {
        headers: { authorization: "Token abc" },
        server: { jwt: { verify: vi.fn() } },
      } as any,
      makeReply(),
    );
    expect(mocks.sendErrorReply.mock.calls.at(-1)?.[1]).toBeInstanceOf(
      MalformedAuthorizationHeaderError,
    );

    mocks.prisma.utente.findUnique.mockResolvedValue(null);
    await authMiddleware(
      {
        headers: { authorization: "Bearer token" },
        server: {
          jwt: {
            verify: vi.fn(() => ({ id: "u1", type: "access" })),
          },
        },
      } as any,
      makeReply(),
    );
    expect(mocks.sendErrorReply).toHaveBeenCalledTimes(3);
  });

  it("requireRole allows sufficient roles and rejects invalid house contexts", async () => {
    const inquilinoOnly = requireRole(Ruolo.Inquilino);
    const homeAdminOnly = requireRole(Ruolo.HomeAdmin);

    await inquilinoOnly(
      {
        params: { idCasa: "c1" },
        user: { idCasa: "c1", ruoloCasa: Ruolo.HomeAdmin },
      } as any,
      makeReply(),
    );
    expect(mocks.sendErrorReply).not.toHaveBeenCalled();

    await homeAdminOnly(
      {
        params: { idCasa: "c2" },
        user: { idCasa: "c1", ruoloCasa: Ruolo.HomeAdmin },
      } as any,
      makeReply(),
    );
    expect(mocks.sendErrorReply.mock.calls.at(-1)?.[1]).toBeInstanceOf(
      ForbiddenError,
    );

    await homeAdminOnly(
      {
        params: { idCasa: "c1" },
        user: { idCasa: "c1", ruoloCasa: Ruolo.Inquilino },
      } as any,
      makeReply(),
    );
    expect(mocks.sendErrorReply.mock.calls.at(-1)?.[1]).toBeInstanceOf(
      ForbiddenError,
    );
  });
});

describe("Error mapper coverage", () => {
  it("maps validation, token, auth, http and generic errors", () => {
    const zodResult = z
      .object({ email: z.string().email(), profile: z.object({ age: z.number() }) })
      .safeParse({ email: "bad", profile: { age: "old" } });
    const zodPayload = mapErrorToHttp(
      zodResult.success ? new ZodError([]) : zodResult.error,
    );
    expect(zodPayload).toEqual(
      expect.objectContaining({
        statusCode: 400,
        code: "BAD_REQUEST",
        details: expect.objectContaining({
          email: expect.any(Array),
          "profile.age": expect.any(Array),
        }),
      }),
    );

    expect(mapErrorToHttp(new TokenExpiredError("expired", new Date()))).toEqual(
      expect.objectContaining({ statusCode: 401, code: "TOKEN_EXPIRED" }),
    );
    expect(mapErrorToHttp(new JsonWebTokenError("bad"))).toEqual(
      expect.objectContaining({ statusCode: 401, code: "INVALID_TOKEN" }),
    );

    const appErrors = [
      [new DuplicateUserError(), 409, "DUPLICATE_USER"],
      [new InvalidCredentialsError(), 401, "INVALID_CREDENTIALS"],
      [new MissingAuthTokenError(), 401, "MISSING_AUTH_TOKEN"],
      [new MalformedAuthorizationHeaderError(), 401, "MALFORMED_AUTH_HEADER"],
      [new InvalidTokenPayloadError(), 401, "INVALID_TOKEN_PAYLOAD"],
      [
        new AuthenticatedUserNotFoundError(),
        401,
        "AUTHENTICATED_USER_NOT_FOUND",
      ],
      [new UserNotFoundError(), 404, "USER_NOT_FOUND"],
      [
        new InvalidOrExpiredResetCodeError(),
        400,
        "INVALID_OR_EXPIRED_RESET_CODE",
      ],
      [new EmailDeliveryError(), 502, "EMAIL_DELIVERY_ERROR"],
      [
        new PasswordResetEmailDeliveryError(),
        502,
        "PASSWORD_RESET_EMAIL_DELIVERY_ERROR",
      ],
      [
        new InvalidEmailVerificationTokenError(),
        400,
        "INVALID_EMAIL_VERIFICATION_TOKEN",
      ],
      [new DatabaseCleanupError(), 500, "DATABASE_CLEANUP_ERROR"],
    ] as const;

    for (const [error, statusCode, code] of appErrors) {
      expect(mapErrorToHttp(error)).toEqual(
        expect.objectContaining({ statusCode, code }),
      );
    }

    const httpPayload = mapErrorToHttp(new ForbiddenError("No"));
    expect(httpPayload).toEqual(
      expect.objectContaining({ statusCode: 403, code: "FORBIDDEN" }),
    );

    const internalError = new HttpError(500, "Broken", "BROKEN");
    expect(mapErrorToHttp(internalError)).toEqual(
      expect.objectContaining({ statusCode: 500, stack: expect.any(String) }),
    );
    expect(mapErrorToHttp("unknown")).toEqual(
      expect.objectContaining({
        statusCode: 500,
        code: "INTERNAL_SERVER_ERROR",
      }),
    );
  });
});

describe("Mail utility coverage", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.createTransport.mockReturnValue({
      sendMail: mocks.sendMail.mockResolvedValue(undefined),
      verify: mocks.verifyTransport.mockResolvedValue(undefined),
    });
  });

  it("sends verification and password reset emails through nodemailer", async () => {
    await sendVerificationEmail({
      to: "mario@example.com",
      username: "mario",
      verificationToken: "token-123",
    });

    expect(mocks.createTransport).toHaveBeenCalledWith(
      expect.objectContaining({
        host: "smtp.example.test",
        port: 465,
        secure: true,
        auth: { user: "mailer", pass: "secret" },
      }),
    );
    expect(mocks.sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        from: "CoinCasa <team@example.test>",
        to: "mario@example.com",
        subject: "Verifica la tua email - CoinCasa",
        text: expect.stringContaining("token-123"),
      }),
    );

    await sendPasswordResetEmail({
      to: "mario@example.com",
      username: "mario",
      resetCode: "123456",
      expiresAt: "not-a-date",
    });

    expect(mocks.sendMail).toHaveBeenLastCalledWith(
      expect.objectContaining({
        subject: "Codice di recupero password - CoinCasa",
        text: expect.stringContaining("123456"),
        html: expect.stringContaining("not-a-date"),
      }),
    );
  });
});
