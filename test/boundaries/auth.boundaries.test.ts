/**
 * BOUNDARIES / EDGE CASES — AuthService
 *
 * Obiettivo:
 * - casi limite su reset password: scadenza codice e normalizzazione email (trim/case)
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  InvalidOrExpiredResetCodeError,
  UserNotFoundError,
} from "../../src/errors/appErrors";

const mocks = vi.hoisted(() => ({
  prisma: {
    utente: {
      findUnique: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  },
  argon2: {
    hash: vi.fn(),
    verify: vi.fn(),
    argon2id: 2,
  },
}));

vi.mock("../../src/config/db", () => ({
  prisma: mocks.prisma,
}));

vi.mock("argon2", () => ({
  default: mocks.argon2,
}));

import { AuthService } from "../../src/service/AuthService";

describe("AuthService - boundaries", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  it("password reset code expires after 15 minutes", async () => {
    const t0 = new Date("2026-05-18T10:00:00.000Z");
    vi.setSystemTime(t0);

    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "mario@example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
      passwordHash: "hash",
    });

    const service = new AuthService();

    const req = await service.requestPasswordResetWithValidation({
      email: "mario@example.com",
    });

    // +16 minuti => scaduto
    vi.setSystemTime(new Date(t0.getTime() + 16 * 60 * 1000));

    await expect(
      service.verifyPasswordResetCodeWithValidation({
        email: "mario@example.com",
        codice: req.codice,
      }),
    ).rejects.toBeInstanceOf(InvalidOrExpiredResetCodeError);

    vi.useRealTimers();
  });

  it("verify/reset use the same reset entry even with different email casing and spaces", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "Mario@Example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
      passwordHash: "hash",
    });
    mocks.argon2.hash.mockResolvedValue("new-hash");
    mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

    const service = new AuthService();

    const req = await service.requestPasswordResetWithValidation({
      email: "Mario@Example.com",
    });

    await expect(
      service.verifyPasswordResetCodeWithValidation({
        email: "mario@example.com",
        codice: req.codice,
      }),
    ).resolves.toEqual(expect.objectContaining({ ok: true }));

    await expect(
      service.resetPasswordWithValidation({
        email: "MARIO@EXAMPLE.COM",
        codice: req.codice,
        nuovaPassword: "new-password-123",
      }),
    ).resolves.toEqual(expect.objectContaining({ ok: true }));

    vi.useRealTimers();
  });

  it("resetPasswordWithValidation returns UserNotFoundError when email not in DB", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue(null);

    const service = new AuthService();
    await expect(
      service.resetPasswordWithValidation({
        email: "missing@example.com",
        codice: "123456",
        nuovaPassword: "new-password-123",
      }),
    ).rejects.toBeInstanceOf(UserNotFoundError);

    vi.useRealTimers();
  });
});

