import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  UserNotFoundError,
  EmailDeliveryError,
  DuplicateUserError,
} from "../../src/errors/appErrors";
import { ConflictError } from "../../src/errors/httpErrors";

const mocks = vi.hoisted(() => {
  const utenteFind = vi.fn();
  const utenteUpdate = vi.fn();

  const tx = {
    utente: { findUnique: utenteFind, update: utenteUpdate },
    membroCasa: {
      findMany: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
      update: vi.fn(),
    },
    spesa: { deleteMany: vi.fn() },
    quotaSpesa: { deleteMany: vi.fn() },
    turno: { deleteMany: vi.fn() },
    problema: { deleteMany: vi.fn() },
    documento: { deleteMany: vi.fn() },
    scadenza: { deleteMany: vi.fn() },
    casa: { delete: vi.fn() },
  };

  return {
    prisma: {
      utente: {
        findUnique: utenteFind,
        findFirst: vi.fn(),
        update: utenteUpdate,
        delete: vi.fn(),
      },
      $transaction: vi.fn((cb: (tx: unknown) => Promise<unknown>) => cb(tx)),
    },
    tx,
    mail: {
      sendVerificationMail: vi.fn(),
    },
  };
});

vi.mock("../../src/config/db", () => ({
  prisma: mocks.prisma,
}));

vi.mock("../../src/utils/mail", () => ({
  sendVerificationEmail: mocks.mail.sendVerificationMail,
}));

import { AccountService } from "../../src/service/AccountService";

describe("AccountService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("getProfilo", () => {
    it("returns profile if user is found", async () => {
      const dbUser = {
        username: "alice123",
        nome: "Alice",
        cognome: "Rossi",
        email: "alice@example.com",
        dataCreazione: new Date("2026-01-01T00:00:00.000Z"),
      };
      mocks.prisma.utente.findUnique.mockResolvedValue(dbUser);

      const service = new AccountService();
      const result = await service.getProfilo("u1");

      expect(result).toEqual({
        username: "alice123",
        nome: "Alice",
        cognome: "Rossi",
        email: "alice@example.com",
        dataCreazione: dbUser.dataCreazione,
      });
      expect(mocks.prisma.utente.findUnique).toHaveBeenCalledWith({
        where: { id: "u1" },
        select: {
          username: true,
          nome: true,
          cognome: true,
          email: true,
          dataCreazione: true,
        },
      });
    });

    it("throws UserNotFoundError if user is not found", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue(null);

      const service = new AccountService();
      await expect(service.getProfilo("u1")).rejects.toBeInstanceOf(
        UserNotFoundError,
      );
    });
  });

  describe("modificaUsername", () => {
    it("updates username if it is not in use by another user", async () => {
      mocks.prisma.utente.findFirst.mockResolvedValue(null);
      const updatedUser = {
        username: "alice_new",
        nome: "Alice",
        cognome: "Rossi",
        email: "alice@example.com",
        dataCreazione: new Date(),
      };
      mocks.prisma.utente.update.mockResolvedValue(updatedUser);

      const service = new AccountService();
      const result = await service.modificaUsername("u1", {
        username: "alice_new",
      });

      expect(result).toEqual(updatedUser);
      expect(mocks.prisma.utente.findFirst).toHaveBeenCalledWith({
        where: {
          username: "alice_new",
          id: { not: "u1" },
        },
      });
      expect(mocks.prisma.utente.update).toHaveBeenCalledWith({
        where: { id: "u1" },
        data: { username: "alice_new" },
        select: {
          username: true,
          nome: true,
          cognome: true,
          email: true,
          dataCreazione: true,
        },
      });
    });

    it("throws ConflictError if username is already in use by another user", async () => {
      mocks.prisma.utente.findFirst.mockResolvedValue({ id: "u2" });

      const service = new AccountService();
      await expect(
        service.modificaUsername("u1", { username: "alice_new" }),
      ).rejects.toBeInstanceOf(ConflictError);
    });
  });

  describe("modificaEmail", () => {
    it("updates email temporarily and sends verification email", async () => {
      const dbUser = {
        id: "u1",
        username: "alice123",
        email: "alice@example.com",
        emailVerificata: true,
        tokenVerifica: null,
        dataVerificaMail: new Date(),
      };
      mocks.prisma.utente.findUnique
        .mockResolvedValueOnce(dbUser) // first findUnique at start
        .mockResolvedValueOnce(null); // findUnique check for existing email

      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });
      mocks.mail.sendVerificationMail.mockResolvedValue(undefined);

      const service = new AccountService();
      const result = await service.modificaEmail("u1", {
        email: "alice_new@example.com",
      });

      expect(result.newEmail).toBe("alice_new@example.com");
      expect(mocks.prisma.utente.findUnique).toHaveBeenCalledTimes(2);
      expect(mocks.prisma.utente.update).toHaveBeenCalledTimes(1);
      expect(mocks.prisma.utente.update).toHaveBeenLastCalledWith({
        where: { id: "u1" },
        data: {
          email: "alice_new@example.com",
          emailVerificata: false,
          tokenVerifica: expect.any(String),
          dataVerificaMail: null,
        },
      });
      expect(mocks.mail.sendVerificationMail).toHaveBeenCalledTimes(1);
    });

    it("throws DuplicateUserError if new email is in use by another user", async () => {
      const dbUser = {
        id: "u1",
        username: "alice123",
        email: "alice@example.com",
        emailVerificata: true,
        tokenVerifica: null,
        dataVerificaMail: null,
      };
      mocks.prisma.utente.findUnique
        .mockResolvedValueOnce(dbUser) // first findUnique at start
        .mockResolvedValueOnce({ id: "u2" }); // existing user with new email

      const service = new AccountService();
      await expect(
        service.modificaEmail("u1", { email: "alice_new@example.com" }),
      ).rejects.toBeInstanceOf(DuplicateUserError);
    });

    it("rolls back email change if sending verification email fails", async () => {
      const dbUser = {
        id: "u1",
        username: "alice123",
        email: "alice@example.com",
        emailVerificata: true,
        tokenVerifica: "some-token",
        dataVerificaMail: new Date("2026-01-01T00:00:00.000Z"),
      };
      mocks.prisma.utente.findUnique
        .mockResolvedValueOnce(dbUser) // first findUnique at start
        .mockResolvedValueOnce(null); // check duplicate email

      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });
      mocks.mail.sendVerificationMail.mockRejectedValue(
        new Error("SMTP error"),
      );

      const service = new AccountService();
      await expect(
        service.modificaEmail("u1", { email: "alice_new@example.com" }),
      ).rejects.toBeInstanceOf(EmailDeliveryError);

      // Verify rollback update occurred with original values
      expect(mocks.prisma.utente.update).toHaveBeenCalledTimes(2);
      expect(mocks.prisma.utente.update).toHaveBeenLastCalledWith({
        where: { id: "u1" },
        data: {
          email: "alice@example.com",
          emailVerificata: true,
          tokenVerifica: "some-token",
          dataVerificaMail: dbUser.dataVerificaMail,
        },
      });
    });
  });

  describe("eliminaAccount", () => {
    it("anonymizes personal user data", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue({ id: "u1" });
      mocks.tx.membroCasa.findMany.mockResolvedValue([]);
      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

      const service = new AccountService();
      const result = await service.eliminaAccount("u1");

      expect(result.message).toContain("anonimizzati");
      expect(mocks.prisma.utente.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: "u1" },
          data: expect.objectContaining({
            username: expect.stringMatching(/^Utente_/),
            email: "deleted_u1@deleted.local",
            nome: "Anonimo",
            cognome: "Anonimo",
            passwordHash: "DELETED",
            emailVerificata: false,
          }),
        }),
      );
    });

    it("throws UserNotFoundError if user doesn't exist", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue(null);
      mocks.tx.membroCasa.findMany.mockResolvedValue([]);

      const service = new AccountService();
      await expect(service.eliminaAccount("u1")).rejects.toBeInstanceOf(
        UserNotFoundError,
      );
    });

    it("deletes the whole house when the user is the last member", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue({ id: "u1" });
      mocks.tx.membroCasa.findMany
        .mockResolvedValueOnce([{ id: "m1", idCasa: "c1", ruolo: "HomeAdmin" }])
        .mockResolvedValueOnce([
          { id: "m1", idUtente: "u1", ruolo: "HomeAdmin" },
        ]);
      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

      const service = new AccountService();
      await service.eliminaAccount("u1");

      expect(mocks.tx.quotaSpesa.deleteMany).toHaveBeenCalledWith({
        where: { idCasa: "c1" },
      });
      expect(mocks.tx.membroCasa.deleteMany).toHaveBeenCalledWith({
        where: { idCasa: "c1" },
      });
      expect(mocks.tx.casa.delete).toHaveBeenCalledWith({
        where: { id: "c1" },
      });
    });

    it("promotes another tenant when deleting the only HomeAdmin in a shared house", async () => {
      mocks.prisma.utente.findUnique.mockResolvedValue({ id: "u1" });
      mocks.tx.membroCasa.findMany
        .mockResolvedValueOnce([{ id: "m1", idCasa: "c1", ruolo: "HomeAdmin" }])
        .mockResolvedValueOnce([
          { id: "m1", idUtente: "u1", ruolo: "HomeAdmin" },
          { id: "m2", idUtente: "u2", ruolo: "Inquilino" },
        ]);
      mocks.prisma.utente.update.mockResolvedValue({ id: "u1" });

      const service = new AccountService();
      await service.eliminaAccount("u1");

      expect(mocks.tx.membroCasa.update).toHaveBeenCalledWith({
        where: { id: "m2" },
        data: { ruolo: "HomeAdmin" },
      });
      expect(mocks.tx.membroCasa.delete).toHaveBeenCalledWith({
        where: { id: "m1" },
      });
    });
  });
});
