/**
 * VALIDATION TESTS — Spesa DTO (Zod)
 */
import { describe, it, expect } from "vitest";
import { CreaSpesaSchema, ModificaSpesaSchema } from "../../src/dto/SpesaDto";

describe("SpesaDto - validation", () => {
  it("CreaSpesaSchema accepts minimal valid payload", () => {
    const result = CreaSpesaSchema.safeParse({
      descrizione: "Detersivo",
      importo: 12.5,
      partecipanti: ["u1"],
    });

    expect(result.success).toBe(true);
    if (result.success) {
      // default
      expect(result.data.isRicorrente).toBe(false);
    }
  });

  it("CreaSpesaSchema requires cadenzaGiorni when isRicorrente=true and dataScadenza is set", () => {
    const result = CreaSpesaSchema.safeParse({
      descrizione: "Affitto",
      importo: 100,
      partecipanti: ["u1", "u2"],
      dataScadenza: "2026-12-31",
      isRicorrente: true,
    });

    expect(result.success).toBe(false);
  });

  it("ModificaSpesaSchema allows partial update", () => {
    const result = ModificaSpesaSchema.safeParse({
      descrizione: "Nuova descrizione",
    });
    expect(result.success).toBe(true);
  });

  it("ModificaSpesaSchema rejects isRicorrente=true without cadenzaGiorni when dataScadenza is set", () => {
    const result = ModificaSpesaSchema.safeParse({
      dataScadenza: "2026-12-31",
      isRicorrente: true,
    });
    expect(result.success).toBe(false);
  });
});

