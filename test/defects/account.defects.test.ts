/**
 * DEFECT / REGRESSION TESTS — AccountService
 *
 * Scopo:
 * - proteggere gli scenari critici di errore su password, email e account
 * - garantire che la logica di rollback venga invocata correttamente
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  UserNotFoundError,
  InvalidCurrentPasswordError,
  EmailDeliveryError,
  DuplicateUserError,
} from "../../src/errors/appErrors";

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

describe("AccountService - defects", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("modificaPassword", () => {
    it("throws UserNotFoundError when user does not exist", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue(null);

      const service = new AccountService();
      await expect(
        service.modificaPassword("u-missing", {
          oldPassword: "old-password-123",
          newPassword: "new-password-456",
        }),
      ).rejects.toBeInstanceOf(UserNotFoundError);
    });

    it("throws InvalidCurrentPasswordError when old password does not match", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue({
        id: "u1",
        passwordHash: "stored-hash",
      });
      mocks.argon2.verify.mockResolvedValue(false);

      const service = new AccountService();
      await expect(
        service.modificaPassword("u1", {
          oldPassword: "wrong-old-password",
          newPassword: "new-password-456",
        }),
      ).rejects.toBeInstanceOf(InvalidCurrentPasswordError);
    });
  });

  describe("modificaEmail", () => {
    it("throws UserNotFoundError when user does not exist", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue(null);

      const service = new AccountService();
      await expect(
        service.modificaEmail("u-missing", { email: "new@example.com" }),
      ).rejects.toBeInstanceOf(UserNotFoundError);
    });

    it("throws DuplicateUserError when new email is already taken by another user", async () => {
      mocks.prisma.utente.findUnique
        .mockResolvedValueOnce({
          id: "u1",
          username: "alice",
          email: "alice@example.com",
          emailVerificata: true,
          tokenVerifica: null,
          dataVerificaMail: null,
        })
        .mockResolvedValueOnce({ id: "u2" }); // another user owns the new email

      const service = new AccountService();
      await expect(
        service.modificaEmail("u1", { email: "taken@example.com" }),
      ).rejects.toBeInstanceOf(DuplicateUserError);
    });

    it("rolls back email and throws EmailDeliveryError when mail sending fails", async () => {
      const originalUser = {
        id: "u1",
        username: "alice",
        email: "alice@example.com",
        emailVerificata: true,
        tokenVerifica: "old-token",
        dataVerificaMail: new Date("2026-01-01T00:00:00.000Z"),
      };
      mocks.prisma.utente.findUnique
        .mockResolvedValueOnce(originalUser)
        .mockResolvedValueOnce(null); // new email not taken

      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });
      mocks.mail.sendVerificationMail.mockRejectedValue(new Error("SMTP down"));

      const service = new AccountService();
      await expect(
        service.modificaEmail("u1", { email: "new@example.com" }),
      ).rejects.toBeInstanceOf(EmailDeliveryError);

      // First update sets new email; second update rolls back
      expect(mocks.prisma.utente.update).toHaveBeenCalledTimes(2);
      expect(mocks.prisma.utente.update).toHaveBeenLastCalledWith({
        where: { id: "u1" },
        data: {
          email: "alice@example.com",
          emailVerificata: true,
          tokenVerifica: "old-token",
          dataVerificaMail: originalUser.dataVerificaMail,
        },
      });
    });
  });
});
