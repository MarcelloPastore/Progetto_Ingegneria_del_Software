/**
 * BOUNDARIES / EDGE CASES — ScadenzaService
 *
 * Focus:
 * - lista vuota di scadenze
 * - ricorrenza con cadenza minima (1 giorno)
 * - aggiornaRicorrenza usa la cadenza esistente in DB quando il DTO non la specifica
 * - modificaScadenza: patch parziale (solo nome) non altera gli altri campi
 */
import { describe, it, expect, vi, beforeEach } from "vitest";

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

const baseScadenza = {
  id: "s1",
  nome: "Bolletta luce",
  descrizione: "Pagamento utenze",
  dataScadenza: new Date("2026-06-10T00:00:00.000Z"),
  isRicorrente: false,
  cadenzaGiorni: null,
  idCasa: "c1",
  dataCreazione: new Date("2026-06-01T00:00:00.000Z"),
};

describe("ScadenzaService - boundaries", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("getAllScadenze: lista vuota", () => {
    it("returns empty array when no scadenze exist for the casa", async () => {
      mocks.findScadenzeByCasa.mockResolvedValue([]);

      const service = new ScadenzaService();
      const result = await service.getAllScadenze("c1");

      expect(result).toEqual([]);
      expect(result).toHaveLength(0);
    });
  });

  describe("creaScadenza: cadenza minima per ricorrenti", () => {
    it("persists cadenzaGiorni=1 (minimum) for a recurring scadenza", async () => {
      mocks.createScadenza.mockResolvedValue({
        ...baseScadenza,
        isRicorrente: true,
        cadenzaGiorni: 1,
      });

      const service = new ScadenzaService();
      await service.creaScadenza("c1", {
        nome: "Bolletta",
        descrizione: "",
        dataScadenza: new Date("2026-07-01"),
        isRicorrente: true,
        cadenzaGiorni: 1,
      });

      expect(mocks.createScadenza).toHaveBeenCalledWith(
        expect.objectContaining({ isRicorrente: true, cadenzaGiorni: 1 }),
      );
    });

    it("stores cadenzaGiorni=null when isRicorrente=false even if cadenza is provided", async () => {
      mocks.createScadenza.mockResolvedValue(baseScadenza);

      const service = new ScadenzaService();
      await service.creaScadenza("c1", {
        nome: "Bolletta",
        descrizione: "",
        dataScadenza: new Date("2026-07-01"),
        isRicorrente: false,
        cadenzaGiorni: 30,
      });

      expect(mocks.createScadenza).toHaveBeenCalledWith(
        expect.objectContaining({ isRicorrente: false, cadenzaGiorni: null }),
      );
    });
  });

  describe("aggiornaRicorrenza: cadenza ereditata dal DB", () => {
    it("uses existing DB cadenza when dto does not provide one", async () => {
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

    it("overrides existing cadenza when dto provides a new value", async () => {
      mocks.findScadenzaByIdOrThrow.mockResolvedValue({
        ...baseScadenza,
        isRicorrente: true,
        cadenzaGiorni: 14,
      });
      mocks.updateScadenza.mockResolvedValue({
        ...baseScadenza,
        isRicorrente: true,
        cadenzaGiorni: 7,
      });

      const service = new ScadenzaService();
      await service.aggiornaRicorrenza("c1", "s1", { isRicorrente: true, cadenzaGiorni: 7 });

      expect(mocks.updateScadenza).toHaveBeenCalledWith("s1", {
        isRicorrente: true,
        cadenzaGiorni: 7,
      });
    });

    it("clears cadenza when disabling ricorrenza", async () => {
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
  });

  describe("modificaScadenza: patch parziale", () => {
    it("updates only nome and does not include other fields in the update payload", async () => {
      mocks.findScadenzaByIdOrThrow.mockResolvedValue(baseScadenza);
      mocks.updateScadenza.mockResolvedValue({ ...baseScadenza, nome: "Bolletta gas" });

      const service = new ScadenzaService();
      await service.modificaScadenza("c1", "s1", { nome: "Bolletta gas" });

      expect(mocks.updateScadenza).toHaveBeenCalledWith("s1", { nome: "Bolletta gas" });
    });

    it("updates dataScadenza without touching nome or descrizione", async () => {
      mocks.findScadenzaByIdOrThrow.mockResolvedValue(baseScadenza);
      const newDate = new Date("2026-12-31");
      mocks.updateScadenza.mockResolvedValue({ ...baseScadenza, dataScadenza: newDate });

      const service = new ScadenzaService();
      await service.modificaScadenza("c1", "s1", { dataScadenza: newDate });

      expect(mocks.updateScadenza).toHaveBeenCalledWith("s1", { dataScadenza: newDate });
    });
  });
});
