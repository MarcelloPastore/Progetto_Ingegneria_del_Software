/**
 * VALIDATION TESTS — Problema DTO (Zod)
 */
import { describe, it, expect } from "vitest";
import {
  CreaProblemaSchema,
  AssegnaProblemaSchema,
  AggiornaStatoSchema,
  AggiornaPrioritaSchema,
  ModificaProblemaSchema,
} from "../../src/dto/ProblemaDto";

describe("ProblemaDto - validation", () => {
  it("CreaProblemaSchema accepts valid payload", () => {
    const result = CreaProblemaSchema.safeParse({
      nome: "Rubinetto",
      descrizione: "Perde acqua",
      priorita: "Urgente",
    });
    expect(result.success).toBe(true);
  });

  it("CreaProblemaSchema rejects empty nome", () => {
    const result = CreaProblemaSchema.safeParse({
      nome: "",
      descrizione: "x",
    });
    expect(result.success).toBe(false);
  });

  it("AssegnaProblemaSchema allows null idUtente (unassign)", () => {
    const result = AssegnaProblemaSchema.safeParse({ idUtente: null });
    expect(result.success).toBe(true);
  });

  it("AggiornaStatoSchema rejects unknown status", () => {
    const result = AggiornaStatoSchema.safeParse({
      // @ts-ignore
      stato: "Unknown",
    });
    expect(result.success).toBe(false);
  });

  it("AggiornaPrioritaSchema accepts valid priority", () => {
    const result = AggiornaPrioritaSchema.safeParse({ priorita: "Media" });
    expect(result.success).toBe(true);
  });

  it("ModificaProblemaSchema rejects empty fields", () => {
    const result = ModificaProblemaSchema.safeParse({ nome: "" });
    expect(result.success).toBe(false);
  });
});
