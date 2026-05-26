/**
 * DEFECT / REGRESSION TESTS — AuthService
 *
 * Scopo:
 * - proteggere scenari critici: codice reset errato/scaduto, email non trovata
 *
 * Nota: alcuni casi sono volutamente ridondanti rispetto ai logic test, ma qui
 * manteniamo solo gli scenari di errore più sensibili.
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

describe("AuthService - defects", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("verifyPasswordResetCodeWithValidation throws if user does not exist", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue(null);

    const service = new AuthService();
    await expect(
      service.verifyPasswordResetCodeWithValidation({
        email: "missing@example.com",
        codice: "123456",
      }),
    ).rejects.toBeInstanceOf(UserNotFoundError);
  });

  it("verifyPasswordResetCodeWithValidation throws for wrong code", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "mario@example.com",
      passwordHash: "hash",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
    });

    const service = new AuthService();

    const req = await service.requestPasswordResetWithValidation({
      email: "mario@example.com",
    });

    await expect(
      service.verifyPasswordResetCodeWithValidation({
        email: "mario@example.com",
        codice: req.codice === "000000" ? "111111" : "000000",
      }),
    ).rejects.toBeInstanceOf(InvalidOrExpiredResetCodeError);
  });
});

