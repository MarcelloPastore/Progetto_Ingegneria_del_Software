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
  addMembroCasa: vi.fn(),
  updateMembroCasaRole: vi.fn(),
  removeMembroCasa: vi.fn(),
}));

vi.mock("crypto", () => ({
  randomUUID: vi.fn(() => "invite-123"),
}));

vi.mock("../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    createCasa = mocks.createCasa;
    findCaseByUser = mocks.findCaseByUser;
    findCasaByIdOrThrow = mocks.findCasaByIdOrThrow;
    findCasaByIdAndInviteLinkOrThrow = mocks.findCasaByIdAndInviteLinkOrThrow;
    updateCasa = mocks.updateCasa;
    deleteCasa = mocks.deleteCasa;
    findMembroCasaByCasaAndUtente = mocks.findMembroCasaByCasaAndUtente;
    findMembroCasaByCasaAndUtenteOrThrow =
      mocks.findMembroCasaByCasaAndUtenteOrThrow;
    addMembroCasa = mocks.addMembroCasa;
    updateMembroCasaRole = mocks.updateMembroCasaRole;
    removeMembroCasa = mocks.removeMembroCasa;
  },
}));

import { Ruolo } from "@prisma/client";
import { CasaService } from "../src/service/CasaService";

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
        inviteLink: "invite-123",
      }),
    );
    expect(result.inviteLink).toBe("invite-123");
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
});
