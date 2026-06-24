import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  createCasa: vi.fn(),
  findCaseByUser: vi.fn(),
  findCasaByIdOrThrow: vi.fn(),
  findCasaByIdAndInviteLinkOrThrow: vi.fn(),
  updateCasa: vi.fn(),
  deleteCasa: vi.fn(),
  findMembroCasaByCasaAndUtente: vi.fn(),
  findMembroCasaByCasaAndUtenteOrThrow: vi.fn(),
  getCasaCreator: vi.fn(),
  addMembroCasa: vi.fn(),
  updateMembroCasaRole: vi.fn(),
  removeMembroCasa: vi.fn(),
}));

vi.mock("node:crypto", () => ({
  randomInt: vi.fn(() => 0),
}));

/* eslint-disable @typescript-eslint/no-unused-vars */
vi.mock("../../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    createCasa(...args: unknown[]) {
      return mocks.createCasa(...args);
    }
    findCaseByUser(...args: unknown[]) {
      return mocks.findCaseByUser(...args);
    }
    findCasaByIdOrThrow(...args: unknown[]) {
      return mocks.findCasaByIdOrThrow(...args);
    }
    findCasaByIdAndInviteLinkOrThrow(...args: unknown[]) {
      return mocks.findCasaByIdAndInviteLinkOrThrow(...args);
    }
    updateCasa(...args: unknown[]) {
      return mocks.updateCasa(...args);
    }
    deleteCasa(...args: unknown[]) {
      return mocks.deleteCasa(...args);
    }
    findMembroCasaByCasaAndUtente(...args: unknown[]) {
      return mocks.findMembroCasaByCasaAndUtente(...args);
    }
    findMembroCasaByCasaAndUtenteOrThrow(...args: unknown[]) {
      return mocks.findMembroCasaByCasaAndUtenteOrThrow(...args);
    }
    getCasaCreator(...args: unknown[]) {
      return mocks.getCasaCreator(...args);
    }
    addMembroCasa(...args: unknown[]) {
      return mocks.addMembroCasa(...args);
    }
    updateMembroCasaRole(...args: unknown[]) {
      return mocks.updateMembroCasaRole(...args);
    }
    removeMembroCasa(...args: unknown[]) {
      return mocks.removeMembroCasa(...args);
    }
  },
}));
/* eslint-enable @typescript-eslint/no-unused-vars */

import { Ruolo } from "@prisma/client";
import { CasaService } from "../../src/service/CasaService";

const baseCasa = {
  id: "c1",
  nome: "Casa Milano",
  indirizzo: "Via Roma 1",
  citta: "Milano",
  tipoCasa: "Appartamento",
  inviteLink: "invite-123",
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
    {
      id: "m2",
      idUtente: "u2",
      ruolo: Ruolo.Inquilino,
      dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
      utenteRel: { id: "u2", username: "bob" },
    },
  ],
};

describe("CasaService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("creaCasa genera invite link e assegna HomeAdmin al creatore", async () => {
    mocks.createCasa.mockResolvedValue(baseCasa);

    const service = new CasaService();
    const result = await service.creaCasa(
      {
        nome: "Casa Milano",
        indirizzo: "Via Roma 1",
        citta: "Milano",
        tipoCasa: "Appartamento",
      },
      "u1",
    );

    expect(mocks.createCasa).toHaveBeenCalledWith(
      expect.objectContaining({
        creator: "u1",
        inviteLink: expect.stringMatching(/^CX-[A-Z0-9]{8}$/),
      }),
    );
    expect(result.inviteLink).toBeTruthy(); // il valore proviene dal mock createCasa
    expect(result.ruoloUtente).toBe(Ruolo.HomeAdmin);
  });

  it("aggiungiInquilino valida l'invite link e aggiunge il membro", async () => {
    mocks.findCasaByIdAndInviteLinkOrThrow.mockResolvedValue(baseCasa);
    mocks.findMembroCasaByCasaAndUtente.mockResolvedValue(null);
    mocks.addMembroCasa.mockResolvedValue({
      id: "m3",
      idUtente: "u3",
      ruolo: Ruolo.Inquilino,
      dataIngresso: new Date("2026-05-18T00:00:00.000Z"),
      utenteRel: { id: "u3", username: "carla" },
    });

    const service = new CasaService();
    const result = await service.aggiungiInquilino(
      "c1",
      { inviteLink: "invite-123" },
      "u3",
    );

    expect(mocks.findCasaByIdAndInviteLinkOrThrow).toHaveBeenCalledWith(
      "c1",
      "invite-123",
    );
    expect(mocks.addMembroCasa).toHaveBeenCalledWith("c1", "u3");
    expect(result.utente.id).toBe("u3");
    expect(result.ruolo).toBe(Ruolo.Inquilino);
  });

  it("getCase maps houses for the authenticated user", async () => {
    mocks.findCaseByUser.mockResolvedValue([baseCasa]);

    const service = new CasaService();
    const result = await service.getCase("u1");

    expect(mocks.findCaseByUser).toHaveBeenCalledWith("u1");
    expect(result[0]).toEqual(
      expect.objectContaining({
        id: "c1",
        nome: "Casa Milano",
        ruoloUtente: Ruolo.HomeAdmin,
        membriTotali: 2,
      }),
    );
  });

  it("getCasa validates membership before returning house details", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[0],
    );
    mocks.findCasaByIdOrThrow.mockResolvedValue(baseCasa);

    const service = new CasaService();
    const result = await service.getCasa("c1", "u1");

    expect(mocks.findMembroCasaByCasaAndUtenteOrThrow).toHaveBeenCalledWith(
      "c1",
      "u1",
    );
    expect(result.membri).toHaveLength(2);
  });

  it("modificaCasa and eliminaCasa require HomeAdmin membership", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[0],
    );
    mocks.updateCasa.mockResolvedValue({ ...baseCasa, nome: "Casa nuova" });
    mocks.deleteCasa.mockResolvedValue(undefined);

    const service = new CasaService();
    const updated = await service.modificaCasa("c1", "u1", {
      nome: "Casa nuova",
    });
    await service.eliminaCasa("c1", "u1");

    expect(mocks.updateCasa).toHaveBeenCalledWith("c1", {
      nome: "Casa nuova",
    });
    expect(updated.nome).toBe("Casa nuova");
    expect(mocks.deleteCasa).toHaveBeenCalledWith("c1");
  });

  it("rejects admin operations from non HomeAdmin members", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[1],
    );

    const service = new CasaService();

    await expect(
      service.modificaCasa("c1", "u2", { nome: "No" }),
    ).rejects.toThrow("Solo un HomeAdmin");
    expect(mocks.updateCasa).not.toHaveBeenCalled();
  });

  it("returns all members and a single member after membership validation", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow
      .mockResolvedValueOnce(baseCasa.membri[0])
      .mockResolvedValueOnce(baseCasa.membri[0])
      .mockResolvedValueOnce(baseCasa.membri[1]);
    mocks.findCasaByIdOrThrow.mockResolvedValue(baseCasa);

    const service = new CasaService();
    const all = await service.getAllInquilini("c1", "u1");
    const one = await service.getInquilino("c1", "u2", "u1");

    expect(all).toHaveLength(2);
    expect(one.utente.id).toBe("u2");
  });

  it("rejects adding an already present tenant", async () => {
    mocks.findCasaByIdAndInviteLinkOrThrow.mockResolvedValue(baseCasa);
    mocks.findMembroCasaByCasaAndUtente.mockResolvedValue(baseCasa.membri[1]);

    const service = new CasaService();

    await expect(
      service.aggiungiInquilino("c1", { inviteLink: "invite-123" }, "u2"),
    ).rejects.toThrow("gia parte");
    expect(mocks.addMembroCasa).not.toHaveBeenCalled();
  });

  it("rimuoviInquilino blocks owner removal and removes normal members", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[0],
    );
    mocks.getCasaCreator.mockResolvedValueOnce("u1").mockResolvedValueOnce("u1");
    mocks.removeMembroCasa.mockResolvedValue(undefined);

    const service = new CasaService();

    await expect(service.rimuoviInquilino("c1", "u1", "u1")).rejects.toThrow(
      "proprietario",
    );
    await service.rimuoviInquilino("c1", "u2", "u1");

    expect(mocks.removeMembroCasa).toHaveBeenCalledWith("c1", "u2");
  });

  it("modificaRuolo blocks owner role changes and updates normal members", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[0],
    );
    mocks.getCasaCreator.mockResolvedValueOnce("u1").mockResolvedValueOnce("u1");
    mocks.updateMembroCasaRole.mockResolvedValue({
      ...baseCasa.membri[1],
      ruolo: Ruolo.HomeAdmin,
    });

    const service = new CasaService();

    await expect(
      service.modificaRuolo("c1", "u1", { ruolo: Ruolo.Inquilino }, "u1"),
    ).rejects.toThrow("ruolo del proprietario");

    const updated = await service.modificaRuolo(
      "c1",
      "u2",
      { ruolo: Ruolo.HomeAdmin },
      "u1",
    );

    expect(mocks.updateMembroCasaRole).toHaveBeenCalledWith(
      "c1",
      "u2",
      Ruolo.HomeAdmin,
    );
    expect(updated.ruolo).toBe(Ruolo.HomeAdmin);
  });

  it("generaLink reuses existing invite link or regenerates it", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[0],
    );
    mocks.findCasaByIdOrThrow.mockResolvedValue(baseCasa);
    mocks.updateCasa.mockResolvedValue({
      ...baseCasa,
      inviteLink: "CX-AAAAAAAA",
    });

    const service = new CasaService();

    await expect(service.generaLink("c1", "u1", false)).resolves.toEqual({
      inviteLink: "invite-123",
    });
    await expect(service.generaLink("c1", "u1", true)).resolves.toEqual({
      inviteLink: "CX-AAAAAAAA",
    });
    expect(mocks.updateCasa).toHaveBeenCalledWith("c1", {
      inviteLink: "CX-AAAAAAAA",
    });
  });

  it("selectCasa returns the selected house role", async () => {
    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue(
      baseCasa.membri[0],
    );

    const service = new CasaService();
    await expect(service.selectCasa("c1", "u1")).resolves.toEqual({
      idCasa: "c1",
      ruoloCasa: Ruolo.HomeAdmin,
    });
  });
});
