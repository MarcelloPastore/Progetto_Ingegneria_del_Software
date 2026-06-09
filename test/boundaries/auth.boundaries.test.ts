/**
 * BOUNDARIES / EDGE CASES — AuthService
 *
 * Obiettivo:
 * - casi limite su reset password: scadenza codice e normalizzazione email (trim/case)
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import {
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

