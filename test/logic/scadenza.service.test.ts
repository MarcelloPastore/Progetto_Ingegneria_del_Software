/**
 * LOGIC TESTS — ScadenzaService
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { Ruolo } from "@prisma/client";
import { ConflictError } from "../../src/errors/httpErrors";

const mocks = vi.hoisted(() => ({
  findScadenzeByCasa: vi.fn(),
  findScadenzaByIdOrThrow: vi.fn(),
  createScadenza: vi.fn(),
  updateScadenza: vi.fn(),
  deleteScadenza: vi.fn(),
}));

vi.mock("../../src/repository/ScadenzaRepository", () => ({
  ScadenzaRepository: class {
    constructor() {
      Object.assign(this as any, {
        findScadenzeByCasa: mocks.findScadenzeByCasa,
        findScadenzaByIdOrThrow: mocks.findScadenzaByIdOrThrow,
        createScadenza: mocks.createScadenza,
        updateScadenza: mocks.updateScadenza,
        deleteScadenza: mocks.deleteScadenza,
      });
    }
  },
}));

const casaMocks = vi.hoisted(() => ({
  findMembroCasaByCasaAndUtenteOrThrow: vi.fn().mockResolvedValue({ ruolo: "HomeAdmin" }),
}));

vi.mock("../../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    findMembroCasaByCasaAndUtenteOrThrow = casaMocks.findMembroCasaByCasaAndUtenteOrThrow;
  },
}));

import { ScadenzaService } from "../../src/service/ScadenzaService";

const baseScadenza = {
  id: "s1",
  nome: "Bolletta luce",
  descrizione: "Pagamento utenze",
  dataScadenza: new Date("2026-06-10T00:00:00.000Z"),
  isRicorrente: false,
  cadenzaGiorni: null,
  idCasa: "c1",
  dataCreazione: new Date("2026-06-01T00:00:00.000Z"),
  idCreatore: "user1",
};

describe("ScadenzaService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("getAllScadenze maps repository results", async () => {
    mocks.findScadenzeByCasa.mockResolvedValue([baseScadenza]);

    const service = new ScadenzaService();
    const result = await service.getAllScadenze("c1");

    expect(result).toHaveLength(1);
    expect(result[0]).toEqual(
      expect.objectContaining({
        id: "s1",
        nome: "Bolletta luce",
        idCasa: "c1",
      }),
    );
  });

  it("creaScadenza uses defaults when ricorrenza is false", async () => {
    mocks.createScadenza.mockResolvedValue(baseScadenza);

    const service = new ScadenzaService();
    await service.creaScadenza("c1", {
      nome: "Bolletta luce",
      descrizione: "Pagamento utenze",
      isRicorrente: false,
      dataScadenza: new Date("2026-06-10T00:00:00.000Z"),
    }, "user1");

    expect(mocks.createScadenza).toHaveBeenCalledWith(
      expect.objectContaining({
        isRicorrente: false,
        cadenzaGiorni: null,
      }),
    );
  });

  it("creaScadenza throws when ricorrenza=true and cadenza missing", async () => {
    const service = new ScadenzaService();

    await expect(
      service.creaScadenza("c1", {
        nome: "Bolletta luce",
        descrizione: "Pagamento utenze",
        dataScadenza: new Date("2026-06-10T00:00:00.000Z"),
        isRicorrente: true,
      }, "user1"),
    ).rejects.toBeInstanceOf(ConflictError);
  });

  it("modificaScadenza updates only provided fields", async () => {
    mocks.findScadenzaByIdOrThrow.mockResolvedValue(baseScadenza);
    mocks.updateScadenza.mockResolvedValue({
      ...baseScadenza,
      nome: "Bolletta gas",
    });

    const service = new ScadenzaService();
    await service.modificaScadenza("c1", "s1", { nome: "Bolletta gas" }, "user1");

    expect(mocks.updateScadenza).toHaveBeenCalledWith(
      "s1",
      expect.objectContaining({ nome: "Bolletta gas" }),
    );
  });

  it("aggiornaRicorrenza disables recurrence and clears cadenza", async () => {
    mocks.findScadenzaByIdOrThrow.mockResolvedValue({
      ...baseScadenza,
      isRicorrente: true,
      cadenzaGiorni: 30,
    });
    mocks.updateScadenza.mockResolvedValue({
      ...baseScadenza,
      isRicorrente: false,
      cadenzaGiorni: null,
    });

    const service = new ScadenzaService();
    await service.aggiornaRicorrenza("c1", "s1", { isRicorrente: false });

    expect(mocks.updateScadenza).toHaveBeenCalledWith("s1", {
      isRicorrente: false,
      cadenzaGiorni: null,
    });
  });

  it("aggiornaRicorrenza keeps existing cadenza when not provided", async () => {
    mocks.findScadenzaByIdOrThrow.mockResolvedValue({
      ...baseScadenza,
      isRicorrente: true,
      cadenzaGiorni: 14,
    });
    mocks.updateScadenza.mockResolvedValue({
      ...baseScadenza,
      isRicorrente: true,
      cadenzaGiorni: 14,
    });

    const service = new ScadenzaService();
    await service.aggiornaRicorrenza("c1", "s1", { isRicorrente: true });

    expect(mocks.updateScadenza).toHaveBeenCalledWith("s1", {
      isRicorrente: true,
      cadenzaGiorni: 14,
    });
  });

  it("aggiornaRicorrenza throws when enabling without any cadenza", async () => {
    mocks.findScadenzaByIdOrThrow.mockResolvedValue({
      ...baseScadenza,
      isRicorrente: false,
      cadenzaGiorni: null,
    });

    const service = new ScadenzaService();

    await expect(
      service.aggiornaRicorrenza("c1", "s1", { isRicorrente: true }),
    ).rejects.toBeInstanceOf(ConflictError);
  });

  it("eliminaScadenza loads then deletes", async () => {
    mocks.findScadenzaByIdOrThrow.mockResolvedValue(baseScadenza);
    mocks.deleteScadenza.mockResolvedValue(undefined);

    const service = new ScadenzaService();
    await service.eliminaScadenza("c1", "s1", "user1");

    expect(mocks.findScadenzaByIdOrThrow).toHaveBeenCalledWith("c1", "s1");
    expect(mocks.deleteScadenza).toHaveBeenCalledWith("c1", "s1");
  });
});

