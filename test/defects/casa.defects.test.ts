/**
 * DEFECT / REGRESSION TESTS — CasaService
 *
 * Scopo:
 * - proteggere i controlli di autorizzazione (HomeAdmin vs Inquilino)
 * - proteggere il vincolo di unicità di membership (ConflictError)
 * - garantire che l'owner non possa essere rimosso o modificato di ruolo
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { Ruolo } from "@prisma/client";
import { ConflictError, ForbiddenError } from "../../src/errors/httpErrors";

const mocks = vi.hoisted(() => ({
  findCasaByIdAndInviteLinkOrThrow: vi.fn(),
  findCasaByInviteCodeOrThrow: vi.fn(),
  findMembroCasaByCasaAndUtente: vi.fn(),
  findMembroCasaByCasaAndUtenteOrThrow: vi.fn(),
  addMembroCasa: vi.fn(),
  updateCasa: vi.fn(),
  deleteCasa: vi.fn(),
  getCasaCreator: vi.fn(),
  removeMembroCasa: vi.fn(),
  updateMembroCasaRole: vi.fn(),
  findCasaByIdOrThrow: vi.fn(),
  createCasa: vi.fn(),
  findCaseByUser: vi.fn(),
  getHubCounts: vi.fn(),
}));

/* eslint-disable @typescript-eslint/no-unused-vars */
vi.mock("../../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    findCasaByIdAndInviteLinkOrThrow(...a: unknown[]) { return mocks.findCasaByIdAndInviteLinkOrThrow(...a); }
    findCasaByInviteCodeOrThrow(...a: unknown[]) { return mocks.findCasaByInviteCodeOrThrow(...a); }
    findMembroCasaByCasaAndUtente(...a: unknown[]) { return mocks.findMembroCasaByCasaAndUtente(...a); }
    findMembroCasaByCasaAndUtenteOrThrow(...a: unknown[]) { return mocks.findMembroCasaByCasaAndUtenteOrThrow(...a); }
    addMembroCasa(...a: unknown[]) { return mocks.addMembroCasa(...a); }
    updateCasa(...a: unknown[]) { return mocks.updateCasa(...a); }
    deleteCasa(...a: unknown[]) { return mocks.deleteCasa(...a); }
    getCasaCreator(...a: unknown[]) { return mocks.getCasaCreator(...a); }
    removeMembroCasa(...a: unknown[]) { return mocks.removeMembroCasa(...a); }
    updateMembroCasaRole(...a: unknown[]) { return mocks.updateMembroCasaRole(...a); }
    findCasaByIdOrThrow(...a: unknown[]) { return mocks.findCasaByIdOrThrow(...a); }
    createCasa(...a: unknown[]) { return mocks.createCasa(...a); }
    findCaseByUser(...a: unknown[]) { return mocks.findCaseByUser(...a); }
    getHubCounts(...a: unknown[]) { return mocks.getHubCounts(...a); }
  },
}));
/* eslint-enable @typescript-eslint/no-unused-vars */

import { CasaService } from "../../src/service/CasaService";

const inquilinoMembro = {
  id: "m2",
  idUtente: "u2",
  ruolo: Ruolo.Inquilino,
  dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
  utenteRel: { id: "u2", username: "bob" },
};

const adminMembro = {
  id: "m1",
  idUtente: "u1",
  ruolo: Ruolo.HomeAdmin,
  dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
  utenteRel: { id: "u1", username: "alice" },
};

describe("CasaService - defects", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("Authorization: solo HomeAdmin può agire", () => {
    it("modificaCasa throws ForbiddenError when caller is Inquilino", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(inquilinoMembro);

      const service = new CasaService();
      await expect(
        service.modificaCasa("c1", "u2", { nome: "Nuova casa" }),
      ).rejects.toBeInstanceOf(ForbiddenError);
    });

    it("eliminaCasa throws ForbiddenError when caller is Inquilino", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(inquilinoMembro);

      const service = new CasaService();
      await expect(service.eliminaCasa("c1", "u2")).rejects.toBeInstanceOf(ForbiddenError);
    });

    it("generaLink throws ForbiddenError when caller is Inquilino", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(inquilinoMembro);

      const service = new CasaService();
      await expect(service.generaLink("c1", "u2")).rejects.toBeInstanceOf(ForbiddenError);
    });
  });

  describe("Protezione owner: non rimuovibile né modificabile di ruolo", () => {
    it("rimuoviInquilino throws ForbiddenError when trying to remove the owner", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(adminMembro);
      mocks.getCasaCreator.mockResolvedValue("u-owner");

      const service = new CasaService();
      await expect(
        service.rimuoviInquilino("c1", "u-owner", "u1"),
      ).rejects.toBeInstanceOf(ForbiddenError);
    });

    it("modificaRuolo throws ForbiddenError when trying to change owner's role", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(adminMembro);
      mocks.getCasaCreator.mockResolvedValue("u-owner");

      const service = new CasaService();
      await expect(
        service.modificaRuolo("c1", "u-owner", { ruolo: Ruolo.Inquilino }, "u1"),
      ).rejects.toBeInstanceOf(ForbiddenError);
    });
  });

  describe("Membership duplicata: ConflictError", () => {
    it("aggiungiInquilino throws ConflictError when user is already a member", async () => {
      mocks.findCasaByIdAndInviteLinkOrThrow.mockResolvedValue({ id: "c1" });
      mocks.findMembroCasaByCasaAndUtente.mockResolvedValue(inquilinoMembro);

      const service = new CasaService();
      await expect(
        service.aggiungiInquilino("c1", { inviteLink: "inv-123" }, "u2"),
      ).rejects.toBeInstanceOf(ConflictError);
    });

    it("joinCasaConInviteCode throws ConflictError when user is already a member", async () => {
      mocks.findCasaByInviteCodeOrThrow.mockResolvedValue({ id: "c1" });
      mocks.findMembroCasaByCasaAndUtente.mockResolvedValue(inquilinoMembro);

      const service = new CasaService();
      await expect(
        service.joinCasaConInviteCode({ inviteCode: "CX-ABCD1234" }, "u2"),
      ).rejects.toBeInstanceOf(ConflictError);
    });
  });
});
