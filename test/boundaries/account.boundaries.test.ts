/**
 * BOUNDARIES / EDGE CASES — AccountService
 *
 * Focus:
 * - modificaUsername: lo stesso utente può "riconfermare" il proprio username senza conflitto
 * - modificaPassword: hash della nuova password viene chiamato correttamente
 * - eliminaAccount: il campo username viene troncato ai primi 8 caratteri dell'id
 * - getProfilo: restituisce esattamente i campi dal DB
 */
import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  prisma: {
    utente: {
      findUnique: vi.fn(),
      findFirst: vi.fn(),
      update: vi.fn(),
    },
  },
  argon2: {
    verify: vi.fn(),
    hash: vi.fn(),
    argon2id: 2,
  },
  mail: {
    sendVerificationMail: vi.fn(),
  },
}));

vi.mock("../../src/config/db", () => ({
  prisma: mocks.prisma,
}));

vi.mock("argon2", () => ({
  default: mocks.argon2,
}));

vi.mock("../../src/utils/mail", () => ({
  sendVerificationEmail: mocks.mail.sendVerificationMail,
}));

import { AccountService } from "../../src/service/AccountService";

describe("AccountService - boundaries", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("getProfilo", () => {
    it("returns exact user data from DB without transformation", async () => {
      const dbDate = new Date("2026-01-15T08:30:00.000Z");
      mocks.prisma.utente.findUnique.mockResolvedValue({
        username: "mario_rossi",
        nome: "Mario",
        cognome: "Rossi",
        email: "mario.rossi@example.com",
        dataCreazione: dbDate,
      });

      const service = new AccountService();
      const result = await service.getProfilo("u1");

      expect(result.username).toBe("mario_rossi");
      expect(result.dataCreazione).toBe(dbDate);
    });
  });

  describe("modificaUsername: no conflitto con se stesso", () => {
    it("allows user to update with their current username (no self-conflict)", async () => {
      mocks.prisma.utente.findFirst.mockResolvedValue(null); // nessun altro utente con lo stesso username
      const updatedUser = {
        username: "alice",
        nome: "Alice",
        cognome: "Rossi",
        email: "alice@example.com",
        dataCreazione: new Date("2026-01-01T00:00:00.000Z"),
      };
      mocks.prisma.utente.update.mockResolvedValue(updatedUser);

      const service = new AccountService();
      const result = await service.modificaUsername("u1", { username: "alice" });

      expect(result.username).toBe("alice");
      expect(mocks.prisma.utente.findFirst).toHaveBeenCalledWith({
        where: { username: "alice", id: { not: "u1" } },
      });
    });
  });

  describe("modificaPassword: hashing", () => {
    it("hashes new password before saving", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue({
        id: "u1",
        passwordHash: "old-hash",
      });
      mocks.argon2.verify.mockResolvedValue(true);
      mocks.argon2.hash.mockResolvedValue("new-hashed");
      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

      const service = new AccountService();
      const result = await service.modificaPassword("u1", {
        oldPassword: "old-password-123",
        newPassword: "new-password-456",
      });

      expect(mocks.argon2.hash).toHaveBeenCalledWith("new-password-456");
      expect(mocks.prisma.utente.update).toHaveBeenCalledWith({
        where: { id: "u1" },
        data: { passwordHash: "new-hashed" },
      });
      expect(result.message).toContain("successo");
    });
  });

  describe("modificaEmail: conferma via mail", () => {
    it("sends verification email to the new address", async () => {
      const dbUser = {
        id: "u1",
        username: "alice",
        email: "alice@example.com",
        emailVerificata: true,
        tokenVerifica: null,
        dataVerificaMail: new Date(),
      };
      mocks.prisma.utente.findUnique
        .mockResolvedValueOnce(dbUser)
        .mockResolvedValueOnce(null);
      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });
      mocks.mail.sendVerificationMail.mockResolvedValue(undefined);

      const service = new AccountService();
      const result = await service.modificaEmail("u1", { email: "new@example.com" });

      expect(result.newEmail).toBe("new@example.com");
      expect(mocks.mail.sendVerificationMail).toHaveBeenCalledOnce();
      const mailArg = mocks.mail.sendVerificationMail.mock.calls[0]?.[0];
      expect(mailArg?.to).toBe("new@example.com");
    });
  });
});
