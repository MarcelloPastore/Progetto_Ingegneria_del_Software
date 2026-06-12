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
  mail: {
    sendVerificationEmail: vi.fn(),
    sendPasswordResetEmail: vi.fn(),
  },
}));

vi.mock("../../src/config/db", () => ({
  prisma: mocks.prisma,
}));

vi.mock("argon2", () => ({
  default: mocks.argon2,
}));

vi.mock("../../src/utils/mail", () => ({
  sendVerificationEmail: mocks.mail.sendVerificationEmail,
  sendPasswordResetEmail: mocks.mail.sendPasswordResetEmail,
}));

import { AuthService } from "../../src/service/AuthService";

describe("AuthService - defects", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.mail.sendVerificationEmail.mockResolvedValue(undefined);
    mocks.mail.sendPasswordResetEmail.mockResolvedValue(undefined);
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


  it("requestPasswordResetWithValidation throws if the mail provider fails", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "mario@example.com",
      passwordHash: "hash",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
    });

    const failingMailer = vi.fn().mockRejectedValue(new Error("SMTP down"));
    const service = new AuthService({ sendPasswordResetMail: failingMailer });

    await expect(
      service.requestPasswordResetWithValidation({
        email: "mario@example.com",
      }),
    ).rejects.toThrow("Impossibile inviare l'email di recupero password");
  });
});

