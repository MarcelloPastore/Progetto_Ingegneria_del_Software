/**
 * VALIDATION TESTS — CasaDto (Zod schemas)
 *
 * Scopo:
 * - verificare il contratto degli endpoint casa: creazione, modifica, join, ruoli
 * - garantire che i vincoli (nome obbligatorio, formato codice, ruoli validi) restino stabili
 */
import { describe, it, expect } from "vitest";
import {
  CreaCasaSchema,
  ModificaCasaSchema,
  AggiungiInquilinoSchema,
  JoinCasaSchema,
  ModificaRuoloSchema,
} from "../../src/dto/CasaDto";

describe("CasaDto - validation", () => {
  describe("CreaCasaSchema", () => {
    it("accepts valid payload with all fields", () => {
      const result = CreaCasaSchema.safeParse({
        nome: "Casa Milano",
        indirizzo: "Via Roma 1",
        citta: "Milano",
        tipoCasa: "Appartamento",
      });
      expect(result.success).toBe(true);
    });

    it("accepts payload with only the required nome field", () => {
      const result = CreaCasaSchema.safeParse({ nome: "Casa Minima" });
      expect(result.success).toBe(true);
    });

    it("rejects empty nome", () => {
      const result = CreaCasaSchema.safeParse({ nome: "" });
      expect(result.success).toBe(false);
    });

    it("rejects missing nome", () => {
      const result = CreaCasaSchema.safeParse({ indirizzo: "Via Roma 1" });
      expect(result.success).toBe(false);
    });
  });

  describe("ModificaCasaSchema", () => {
    it("accepts empty object (tutti i campi opzionali)", () => {
      const result = ModificaCasaSchema.safeParse({});
      expect(result.success).toBe(true);
    });

    it("accepts partial update with only nome", () => {
      const result = ModificaCasaSchema.safeParse({ nome: "Nuovo nome" });
      expect(result.success).toBe(true);
    });

    it("rejects empty nome in partial update", () => {
      const result = ModificaCasaSchema.safeParse({ nome: "" });
      expect(result.success).toBe(false);
    });
  });

  describe("AggiungiInquilinoSchema", () => {
    it("accepts valid inviteLink", () => {
      const result = AggiungiInquilinoSchema.safeParse({ inviteLink: "CX-ABCD1234" });
      expect(result.success).toBe(true);
    });

    it("rejects missing inviteLink", () => {
      const result = AggiungiInquilinoSchema.safeParse({});
      expect(result.success).toBe(false);
    });

    it("rejects empty inviteLink", () => {
      const result = AggiungiInquilinoSchema.safeParse({ inviteLink: "" });
      expect(result.success).toBe(false);
    });
  });

  describe("JoinCasaSchema", () => {
    it("accepts valid CX- format code", () => {
      const result = JoinCasaSchema.safeParse({ inviteCode: "CX-MDLE4H58" });
      expect(result.success).toBe(true);
    });

    it("rejects code without CX- prefix", () => {
      const result = JoinCasaSchema.safeParse({ inviteCode: "MDLE4H58" });
      expect(result.success).toBe(false);
    });

    it("rejects code with wrong length after CX-", () => {
      const result = JoinCasaSchema.safeParse({ inviteCode: "CX-ABCD" });
      expect(result.success).toBe(false);
    });

    it("rejects code with lowercase letters", () => {
      const result = JoinCasaSchema.safeParse({ inviteCode: "CX-abcd1234" });
      expect(result.success).toBe(false);
    });

    it("rejects empty string", () => {
      const result = JoinCasaSchema.safeParse({ inviteCode: "" });
      expect(result.success).toBe(false);
    });
  });

  describe("ModificaRuoloSchema", () => {
    it("accepts HomeAdmin role", () => {
      const result = ModificaRuoloSchema.safeParse({ ruolo: "HomeAdmin" });
      expect(result.success).toBe(true);
    });

    it("accepts Inquilino role", () => {
      const result = ModificaRuoloSchema.safeParse({ ruolo: "Inquilino" });
      expect(result.success).toBe(true);
    });

    it("rejects unknown role", () => {
      const result = ModificaRuoloSchema.safeParse({ ruolo: "SuperAdmin" });
      expect(result.success).toBe(false);
    });

    it("rejects missing ruolo", () => {
      const result = ModificaRuoloSchema.safeParse({});
      expect(result.success).toBe(false);
    });
  });
});
