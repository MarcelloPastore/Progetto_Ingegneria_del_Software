/**
 * LOGIC TESTS — AuthService
 *
 * Qui testiamo la logica dell'autenticazione isolandola dal DB e dalle librerie crypto.
 *
 * Nota: AuthService usa Prisma direttamente (`src/config/db`) e argon2.
 * Nei test mockiamo entrambe le dipendenze.
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  DuplicateUserError,
  InvalidCredentialsError,
  UserNotFoundError,
  InvalidOrExpiredResetCodeError,
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

describe("AuthService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("registerWithValidation creates user when email/username are free", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue(null);
    mocks.prisma.utente.findFirst.mockResolvedValue(null);
    mocks.argon2.hash.mockResolvedValue("hashed");
    mocks.prisma.utente.create.mockResolvedValue({ id: "u1" });

    const service = new AuthService();
    const result = await service.registerWithValidation({
      email: "mario.rossi@example.com",
      username: "mario",
      password: "super-secure-123",
      nome: "Mario",
      cognome: "Rossi",
    });

    expect(result).toEqual({ id: "u1", message: "Registrazione completata" });
    expect(mocks.argon2.hash).toHaveBeenCalledTimes(1);
    expect(mocks.prisma.utente.create).toHaveBeenCalledTimes(1);
  });

  it("register throws DuplicateUserError when email already exists", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({ id: "u1" });

    const service = new AuthService();
    await expect(
      service.registerWithValidation({
        email: "mario.rossi@example.com",
        username: "mario",
        password: "super-secure-123",
        nome: "Mario",
        cognome: "Rossi",
      }),
    ).rejects.toBeInstanceOf(DuplicateUserError);
  });

  it("loginWithValidation returns user when credentials are valid", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "mario@example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
      passwordHash: "hash",
    });
    mocks.argon2.verify.mockResolvedValue(true);

    const service = new AuthService();
    const result = await service.loginWithValidation({
      email: "mario@example.com",
      password: "super-secure-123",
    });

    expect(result.shouldSign).toBe(true);
    expect(result.user).toEqual({
      id: "u1",
      email: "mario@example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
    });
  });

  it("loginWithValidation throws InvalidCredentialsError when password mismatch", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "mario@example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
      passwordHash: "hash",
    });
    mocks.argon2.verify.mockResolvedValue(false);

    const service = new AuthService();
    await expect(
      service.loginWithValidation({
        email: "mario@example.com",
        password: "wrong",
      }),
    ).rejects.toBeInstanceOf(InvalidCredentialsError);
  });

  it("password reset flow: request -> verify -> reset succeeds (email case-insensitive)", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "TeSt@Example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
      passwordHash: "hash",
    });
    mocks.argon2.hash.mockResolvedValue("new-hash");
    mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

    const service = new AuthService();

    const req = await service.requestPasswordResetWithValidation({
      email: "TeSt@Example.com",
    });
    expect(req.ok).toBe(true);
    expect(req.codice).toMatch(/^\d{6}$/);

    const verify = await service.verifyPasswordResetCodeWithValidation({
      email: "test@example.com",
      codice: req.codice,
    });
    expect(verify.ok).toBe(true);

    const reset = await service.resetPasswordWithValidation({
      email: "TEST@example.com",
      codice: req.codice,
      nuovaPassword: "new-password-123",
    });
    expect(reset.ok).toBe(true);
    expect(mocks.prisma.utente.update).toHaveBeenCalledTimes(1);
  });

  it("requestPasswordResetWithValidation throws UserNotFoundError if email is unknown", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue(null);

    const service = new AuthService();
    await expect(
      service.requestPasswordResetWithValidation({ email: "missing@example.com" }),
    ).rejects.toBeInstanceOf(UserNotFoundError);
  });

  it("resetPasswordWithValidation invalidates code (second use throws)", async () => {
    mocks.prisma.utente.findUnique.mockResolvedValue({
      id: "u1",
      email: "mario@example.com",
      username: "mario",
      nome: "Mario",
      cognome: "Rossi",
      passwordHash: "hash",
    });
    mocks.argon2.hash.mockResolvedValue("new-hash");
    mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

    const service = new AuthService();
    const req = await service.requestPasswordResetWithValidation({
      email: "mario@example.com",
    });

    await service.resetPasswordWithValidation({
      email: "mario@example.com",
      codice: req.codice,
      nuovaPassword: "new-password-123",
    });

    await expect(
      service.resetPasswordWithValidation({
        email: "mario@example.com",
        codice: req.codice,
        nuovaPassword: "another-password-123",
      }),
    ).rejects.toBeInstanceOf(InvalidOrExpiredResetCodeError);
  });
});


