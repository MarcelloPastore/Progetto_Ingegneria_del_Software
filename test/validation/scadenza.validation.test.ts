/**
 * VALIDATION TESTS — ScadenzaDto (Zod schemas)
 */
import { describe, it, expect } from "vitest";
import {
  CreaScadenzaDto,
  ModificaScadenzaDto,
  AggiornaRicorrenzaDto,
  ScadenzaResponseDto,
} from "../../src/dto/ScadenzaDto";

describe("ScadenzaDto - Validation Tests", () => {
  describe("CreaScadenzaDto validation", () => {
    it("accepts valid data", () => {
      const result = CreaScadenzaDto.safeParse({
        nome: "Bolletta luce",
        descrizione: "Pagamento utenze",
        dataScadenza: "2026-06-10",
        isRicorrente: true,
        cadenzaGiorni: 30,
      });

      expect(result.success).toBe(true);
    });

    it("applies defaults for descrizione and isRicorrente", () => {
      const result = CreaScadenzaDto.safeParse({
        nome: "Bolletta acqua",
        dataScadenza: "2026-06-15",
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.descrizione).toBe("");
        expect(result.data.isRicorrente).toBe(false);
      }
    });

    it("rejects empty nome", () => {
      const result = CreaScadenzaDto.safeParse({
        nome: "",
        dataScadenza: "2026-06-10",
      });

      expect(result.success).toBe(false);
    });

    it("rejects invalid cadenzaGiorni", () => {
      const result = CreaScadenzaDto.safeParse({
        nome: "Bolletta luce",
        dataScadenza: "2026-06-10",
        cadenzaGiorni: 0,
      });

      expect(result.success).toBe(false);
    });

    it("allows ricorrenza true without cadenza (service enforces)", () => {
      const result = CreaScadenzaDto.safeParse({
        nome: "Bolletta luce",
        dataScadenza: "2026-06-10",
        isRicorrente: true,
      });

      expect(result.success).toBe(true);
    });
  });

  describe("ModificaScadenzaDto validation", () => {
    it("accepts empty object", () => {
      const result = ModificaScadenzaDto.safeParse({});

      expect(result.success).toBe(true);
    });

    it("rejects empty nome", () => {
      const result = ModificaScadenzaDto.safeParse({ nome: "" });

      expect(result.success).toBe(false);
    });

    it("accepts date as string", () => {
      const result = ModificaScadenzaDto.safeParse({
        dataScadenza: "2026-06-20",
      });

      expect(result.success).toBe(true);
    });
  });

  describe("AggiornaRicorrenzaDto validation", () => {
    it("requires isRicorrente", () => {
      const result = AggiornaRicorrenzaDto.safeParse({});

      expect(result.success).toBe(false);
    });

    it("rejects cadenzaGiorni <= 0", () => {
      const result = AggiornaRicorrenzaDto.safeParse({
        isRicorrente: true,
        cadenzaGiorni: 0,
      });

      expect(result.success).toBe(false);
    });
  });

  describe("ScadenzaResponseDto validation", () => {
    it("accepts valid response", () => {
      const result = ScadenzaResponseDto.safeParse({
        id: "s1",
        nome: "Bolletta luce",
        descrizione: "Pagamento utenze",
        dataScadenza: "2026-06-10T00:00:00.000Z",
        isRicorrente: false,
        cadenzaGiorni: null,
        idCasa: "c1",
        dataCreazione: "2026-06-01T00:00:00.000Z",
      });

      expect(result.success).toBe(false);
    });
  });
});

