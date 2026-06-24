/**
 * BOUNDARIES / EDGE CASES — CasaService
 *
 * Focus:
 * - formato del codice invito generato (CX-XXXXXXXX)
 * - comportamento di generaLink con e senza rigenera
 * - lista case vuota, lista inquilini
 * - join con inviteCode valido aggiunge il membro
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { Ruolo } from "@prisma/client";

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

const baseCasa = {
  id: "c1",
  nome: "Casa Milano",
  indirizzo: "Via Roma 1",
  citta: "Milano",
  tipoCasa: "Appartamento",
  inviteLink: "CX-ABCD1234",
  dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
  creatorRel: { id: "u1", username: "alice" },
  membri: [
    {
      id: "m1",
      idUtente: "u1",
      ruolo: Ruolo.HomeAdmin,
      dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
      utenteRel: { id: "u1", username: "alice" },
    },
  ],
};

const adminMembro = {
  id: "m1",
  idUtente: "u1",
  ruolo: Ruolo.HomeAdmin,
  dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
  utenteRel: { id: "u1", username: "alice" },
};

describe("CasaService - boundaries", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("creaCasa: formato inviteLink", () => {
    it("generates inviteLink in CX-XXXXXXXX format", async () => {
      mocks.createCasa.mockImplementation(async ({ inviteLink, ...rest }: any) => ({
        ...baseCasa,
        ...rest,
        inviteLink,
      }));

      const service = new CasaService();
      const result = await service.creaCasa(
        { nome: "Casa Test", indirizzo: "", citta: "", tipoCasa: "" },
        "u1",
      );

      expect(result.inviteLink).toMatch(/^CX-[A-Z0-9]{8}$/);
    });

    it("assigns HomeAdmin role to creator", async () => {
      mocks.createCasa.mockResolvedValue(baseCasa);

      const service = new CasaService();
      const result = await service.creaCasa({ nome: "Casa Test" }, "u1");

      expect(result.ruoloUtente).toBe(Ruolo.HomeAdmin);
    });
  });

  describe("getCase: lista case", () => {
    it("returns empty array when user has no houses", async () => {
      mocks.findCaseByUser.mockResolvedValue([]);

      const service = new CasaService();
      const result = await service.getCase("u1");

      expect(result).toEqual([]);
    });

    it("returns all houses when user belongs to multiple", async () => {
      const casa2 = { ...baseCasa, id: "c2", nome: "Casa Roma" };
      mocks.findCaseByUser.mockResolvedValue([baseCasa, casa2]);

      const service = new CasaService();
      const result = await service.getCase("u1");

      expect(result).toHaveLength(2);
    });
  });

  describe("generaLink: comportamento rigenera", () => {
    it("returns existing link when rigenera=false (default)", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(adminMembro);
      mocks.findCasaByIdOrThrow.mockResolvedValue(baseCasa);

      const service = new CasaService();
      const result = await service.generaLink("c1", "u1", false);

      expect(result.inviteLink).toBe("CX-ABCD1234");
      expect(mocks.updateCasa).not.toHaveBeenCalled();
    });

    it("regenerates link when rigenera=true", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(adminMembro);
      mocks.updateCasa.mockImplementation(async (_id: string, dto: any) => ({
        ...baseCasa,
        inviteLink: dto.inviteLink,
      }));

      const service = new CasaService();
      const result = await service.generaLink("c1", "u1", true);

      expect(result.inviteLink).toMatch(/^CX-[A-Z0-9]{8}$/);
      expect(mocks.updateCasa).toHaveBeenCalledOnce();
    });
  });

  describe("aggiungiInquilino: join con invite link", () => {
    it("adds new member and returns InquilinoDto", async () => {
      mocks.findCasaByIdAndInviteLinkOrThrow.mockResolvedValue(baseCasa);
      mocks.findMembroCasaByCasaAndUtente.mockResolvedValue(null);
      mocks.addMembroCasa.mockResolvedValue({
        id: "m2",
        idUtente: "u2",
        ruolo: Ruolo.Inquilino,
        dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
        utenteRel: { id: "u2", username: "bob" },
      });

      const service = new CasaService();
      const result = await service.aggiungiInquilino(
        "c1",
        { inviteLink: "CX-ABCD1234" },
        "u2",
      );

      expect(result.utente.id).toBe("u2");
      expect(result.ruolo).toBe(Ruolo.Inquilino);
    });
  });

  describe("getAllInquilini: lista membri", () => {
    it("returns list with single member when solo admin", async () => {
      mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(adminMembro);
      mocks.findCasaByIdOrThrow.mockResolvedValue(baseCasa);

      const service = new CasaService();
      const result = await service.getAllInquilini("c1", "u1");

      expect(result).toHaveLength(1);
      expect(result[0].utente.id).toBe("u1");
    });
  });
});
