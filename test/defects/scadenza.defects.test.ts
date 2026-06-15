/**
 * DEFECT / REGRESSION TESTS — ScadenzaService
 *
 * Scopo:
 * - proteggere il vincolo "cadenza obbligatoria per scadenze ricorrenti"
 * - garantire che i casi limite (cadenza mancante / zero) continuino a lanciare ConflictError
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
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

import { ScadenzaService } from "../../src/service/ScadenzaService";

describe("ScadenzaService - defects", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("creaScadenza: vincolo cadenza per ricorrenti", () => {
    it("throws ConflictError when isRicorrente=true and cadenzaGiorni is missing", async () => {
      const service = new ScadenzaService();
      await expect(
        service.creaScadenza("c1", {
          nome: "Bolletta",
          descrizione: "",
          dataScadenza: new Date("2026-07-01"),
          isRicorrente: true,
        }, "user1"),
      ).rejects.toBeInstanceOf(ConflictError);
    });

    it("throws ConflictError when isRicorrente=true and cadenzaGiorni is null", async () => {
      const service = new ScadenzaService();
      await expect(
        service.creaScadenza("c1", {
          nome: "Bolletta",
          descrizione: "",
          dataScadenza: new Date("2026-07-01"),
          isRicorrente: true,
          cadenzaGiorni: null as any,
        }, "user1"),
      ).rejects.toBeInstanceOf(ConflictError);
    });

    it("does NOT throw when isRicorrente=false even without cadenza", async () => {
      mocks.createScadenza.mockResolvedValue({
        id: "s1",
        nome: "Bolletta",
        descrizione: "",
        dataScadenza: new Date("2026-07-01"),
        isRicorrente: false,
        cadenzaGiorni: null,
        idCasa: "c1",
        dataCreazione: new Date(),
        idCreatore: "user1",
      });

      const service = new ScadenzaService();
      await expect(
        service.creaScadenza("c1", {
          nome: "Bolletta",
          descrizione: "",
          dataScadenza: new Date("2026-07-01"),
          isRicorrente: false,
        }, "user1"),
      ).resolves.toBeDefined();
    });
  });

  describe("aggiornaRicorrenza: vincolo cadenza", () => {
    it("throws ConflictError when enabling ricorrenza without any cadenza in DB or DTO", async () => {
      mocks.findScadenzaByIdOrThrow.mockResolvedValue({
        id: "s1",
        nome: "Bolletta",
        descrizione: "",
        dataScadenza: new Date("2026-07-01"),
        isRicorrente: false,
        cadenzaGiorni: null,
        idCasa: "c1",
        dataCreazione: new Date(),
      });

      const service = new ScadenzaService();
      await expect(
        service.aggiornaRicorrenza("c1", "s1", { isRicorrente: true }),
      ).rejects.toBeInstanceOf(ConflictError);
    });

    it("succeeds when enabling ricorrenza and cadenza is provided in DTO", async () => {
      mocks.findScadenzaByIdOrThrow.mockResolvedValue({
        id: "s1",
        nome: "Bolletta",
        descrizione: "",
        dataScadenza: new Date("2026-07-01"),
        isRicorrente: false,
        cadenzaGiorni: null,
        idCasa: "c1",
        dataCreazione: new Date(),
      });
      mocks.updateScadenza.mockResolvedValue({
        id: "s1",
        nome: "Bolletta",
        descrizione: "",
        dataScadenza: new Date("2026-07-01"),
        isRicorrente: true,
        cadenzaGiorni: 30,
        idCasa: "c1",
        dataCreazione: new Date(),
      });

      const service = new ScadenzaService();
      await expect(
        service.aggiornaRicorrenza("c1", "s1", { isRicorrente: true, cadenzaGiorni: 30 }),
      ).resolves.toBeDefined();
    });
  });
});
