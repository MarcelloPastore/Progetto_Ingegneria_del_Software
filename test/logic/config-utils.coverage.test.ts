import { describe, it, expect, vi, afterEach } from "vitest";
import { getJwt } from "../../src/utils/jwt";
import {
  ConflictError,
  ForbiddenError,
  HttpError,
  NotFoundError,
} from "../../src/errors/httpErrors";

const originalEnv = { ...process.env };

describe("config and utility coverage", () => {
  afterEach(() => {
    process.env = { ...originalEnv };
    vi.resetModules();
  });

  it("parses env defaults and boolean mail options", async () => {
    vi.resetModules();
    process.env = {
      ...originalEnv,
      JWT_SECRET: "secret",
      MAIL_PORT: "587",
      MAIL_SECURE: "1",
      MONGODB_URI: "mongodb://localhost:27017/coincasa_test",
      PORT: "23109",
    };

    const { env } = await import("../../src/config/env");

    expect(env).toEqual(
      expect.objectContaining({
        APP_PUBLIC_URL: "http://localhost:23109",
        JWT_ACCESS_TTL: "14d",
        JWT_SECRET: "secret",
        MAIL_FROM: "no-reply@coincasa.local",
        MAIL_PORT: 587,
        MAIL_SECURE: true,
        MONGODB_URI: "mongodb://localhost:27017/coincasa_test",
        PORT: 23109,
      }),
    );
  });

  it("returns registered JWT plugin or throws a clear setup error", () => {
    const jwt = {
      sign: vi.fn(() => "token"),
      verify: vi.fn(() => ({ idUtente: "u1" })),
    };

    expect(getJwt({ jwt })).toBe(jwt);
    expect(() => getJwt({})).toThrow("JWT plugin non registrato");
  });

  it("constructs HTTP error subclasses with status codes and default codes", () => {
    const teapot = new HttpError(418, "Teapot");
    expect(teapot.statusCode).toBe(418);
    expect(teapot.message).toBe("Teapot");
    expect(teapot.code).toBe("GENERIC_ERROR");

    expect(new ForbiddenError().statusCode).toBe(403);
    expect(new ForbiddenError().code).toBe("FORBIDDEN");
    expect(new ConflictError().statusCode).toBe(409);
    expect(new ConflictError().code).toBe("CONFLICT");
    expect(new NotFoundError().statusCode).toBe(404);
    expect(new NotFoundError().code).toBe("NOT_FOUND");
  });
});
