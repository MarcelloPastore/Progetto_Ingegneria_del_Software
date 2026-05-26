/**
 * VALIDATION TESTS — TurnoDto (Zod schemas)
 *
 * Scopo:
 * - verificare che gli schemi Zod (DTO) accettino input validi e rifiutino input invalidi
 * - garantire default (es. `rotazioneTurno`) e messaggi/constraint attesi
 *
 * Perché è utile:
 * - previene bug lato API dove arrivano payload incompleti o errati
 * - rende esplicito il contratto dei DTO (cosa è obbligatorio/opzionale)
 *
 * Cosa indica un fallimento:
 * - cambiamento involontario del contratto dei DTO
 * - regressione nei default o nelle regole di validazione
 */
import { describe, it, expect } from "vitest";
import {
  CreaTurnoSchema,
  ModificaTurnoSchema,
  AssegnaTurnoSchema,
  TurnoResponseSchema,
  DataTurnoSchema,
  TurnoListItemSchema,
} from "../../src/dto/TurnoDto";

describe("TurnoDto - Validation Tests", () => {
  describe("CreaTurnoSchema validation", () => {
    it("accepts valid turno creation data", () => {
      const validData = {
        task: "Pulizia cucina",
        cadenzaGiorni: 7,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.task).toBe("Pulizia cucina");
        expect(result.data.cadenzaGiorni).toBe(7);
        expect(result.data.rotazioneTurno).toBe(true);
      }
    });

    it("applies default value for rotazioneTurno", () => {
      const dataWithoutRotation = {
        task: "Pulizia bagno",
        cadenzaGiorni: 3,
        assegnatario: "u456",
      };

      const result = CreaTurnoSchema.safeParse(dataWithoutRotation);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.rotazioneTurno).toBe(true);
      }
    });

    it("rejects task with empty string", () => {
      const invalidData = {
        task: "",
        cadenzaGiorni: 7,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0].message).toBe("Campo obbligatorio");
      }
    });

    it("rejects cadenzaGiorni with negative number", () => {
      const invalidData = {
        task: "Pulizia",
        cadenzaGiorni: -5,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("rejects cadenzaGiorni with zero", () => {
      const invalidData = {
        task: "Pulizia",
        cadenzaGiorni: 0,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0].message).toContain("almeno 1 giorno");
      }
    });

    it("rejects cadenzaGiorni with decimal number", () => {
      const invalidData = {
        task: "Pulizia",
        cadenzaGiorni: 7.5,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("rejects assegnatario with empty string", () => {
      const invalidData = {
        task: "Pulizia",
        cadenzaGiorni: 7,
        assegnatario: "",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0].message).toContain("obbligatorio");
      }
    });

    it("rejects non-boolean rotazioneTurno", () => {
      const invalidData = {
        task: "Pulizia",
        cadenzaGiorni: 7,
        assegnatario: "u123",
        rotazioneTurno: "true",
      };

      const result = CreaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("rejects missing required fields", () => {
      const incompleteData = {
        task: "Pulizia",
        cadenzaGiorni: 7,
      };

      const result = CreaTurnoSchema.safeParse(incompleteData);
      expect(result.success).toBe(false);
    });

    it("allows extra fields (Zod default behavior)", () => {
      const dataWithExtra = {
        task: "Pulizia",
        cadenzaGiorni: 7,
        assegnatario: "u123",
        rotazioneTurno: true,
        extraField: "should-not-exist",
      };

      const result = CreaTurnoSchema.safeParse(dataWithExtra);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(Object.keys(result.data)).not.toContain("extraField");
      }
    });

    it("accepts very large cadenzaGiorni", () => {
      const validData = {
        task: "Pulizia",
        cadenzaGiorni: 365,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(validData);
      expect(result.success).toBe(true);
    });

    it("accepts minimum valid cadenzaGiorni", () => {
      const validData = {
        task: "Pulizia",
        cadenzaGiorni: 1,
        assegnatario: "u123",
        rotazioneTurno: true,
      };

      const result = CreaTurnoSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.cadenzaGiorni).toBe(1);
      }
    });
  });

  describe("ModificaTurnoSchema validation", () => {
    it("accepts all optional fields", () => {
      const validData = {
        task: "Nuova pulizia",
        cadenzaGiorni: 14,
        rotazioneTurno: false,
      };

      const result = ModificaTurnoSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.task).toBe("Nuova pulizia");
        expect(result.data.cadenzaGiorni).toBe(14);
        expect(result.data.rotazioneTurno).toBe(false);
      }
    });

    it("accepts empty object (all fields optional)", () => {
      const emptyData = {};

      const result = ModificaTurnoSchema.safeParse(emptyData);
      expect(result.success).toBe(true);
    });

    it("accepts partial update with only task", () => {
      const partialData = { task: "Solo pulizia finestre" };

      const result = ModificaTurnoSchema.safeParse(partialData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.cadenzaGiorni).toBeUndefined();
        expect(result.data.rotazioneTurno).toBeUndefined();
      }
    });

    it("rejects task with empty string", () => {
      const invalidData = { task: "" };

      const result = ModificaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("accepts task with whitespace (validation allows it)", () => {
      const dataWithSpace = { task: "   " };

      const result = ModificaTurnoSchema.safeParse(dataWithSpace);
      expect(result.success).toBe(true);
    });

    it("rejects cadenzaGiorni with zero", () => {
      const invalidData = { cadenzaGiorni: 0 };

      const result = ModificaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("rejects cadenzaGiorni with negative number", () => {
      const invalidData = { cadenzaGiorni: -10 };

      const result = ModificaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("rejects non-boolean rotazioneTurno", () => {
      const invalidData = { rotazioneTurno: "false" };

      const result = ModificaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });
  });

  describe("AssegnaTurnoSchema validation", () => {
    it("accepts valid user ID", () => {
      const validData = { idUtente: "u999" };

      const result = AssegnaTurnoSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.idUtente).toBe("u999");
      }
    });

    it("rejects empty idUtente", () => {
      const invalidData = { idUtente: "" };

      const result = AssegnaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0].message).toContain("richiesto");
      }
    });

    it("rejects missing idUtente", () => {
      const invalidData = {};

      const result = AssegnaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });

    it("rejects non-string idUtente", () => {
      const invalidData = { idUtente: 123 };

      const result = AssegnaTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });
  });

  describe("TurnoResponseSchema validation", () => {
    it("accepts valid turno response", () => {
      const validResponse = {
        id: "t1",
        task: "Pulizia",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatario: { id: "u1", username: "mario" },
        ordineRotazione: ["u1", "u2"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataProssimaPulizia: "2026-05-25T10:30:00Z",
        dataCreazione: "2026-05-18T10:30:00Z",
      };

      const result = TurnoResponseSchema.safeParse(validResponse);
      expect(result.success).toBe(true);
    });

    it("validates ISO date format for dataProssimaPulizia", () => {
      const invalidResponse = {
        id: "t1",
        task: "Pulizia",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatario: { id: "u1", username: "mario" },
        ordineRotazione: [],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataProssimaPulizia: "not-a-date",
        dataCreazione: "2026-05-18T10:30:00Z",
      };

      const result = TurnoResponseSchema.safeParse(invalidResponse);
      expect(result.success).toBe(false);
    });

    it("allows null dataUltimaPulizia", () => {
      const validResponse = {
        id: "t1",
        task: "Pulizia",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatario: { id: "u1", username: "mario" },
        ordineRotazione: [],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataProssimaPulizia: "2026-05-25T10:30:00Z",
        dataCreazione: "2026-05-18T10:30:00Z",
      };

      const result = TurnoResponseSchema.safeParse(validResponse);
      expect(result.success).toBe(true);
    });
  });

  describe("DataTurnoSchema validation", () => {
    it("accepts valid data turno", () => {
      const validData = {
        id: "t1",
        dataProssimaPuliza: "2026-05-25T10:30:00Z",
      };

      const result = DataTurnoSchema.safeParse(validData);
      expect(result.success).toBe(true);
    });

    it("accepts invalid date format (no specific validation)", () => {
      const invalidData = {
        id: "t1",
        dataProssimaPuliza: "invalid-date",
      };

      const result = DataTurnoSchema.safeParse(invalidData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.dataProssimaPuliza).toBe("invalid-date");
      }
    });
  });

  describe("TurnoListItemSchema validation", () => {
    it("accepts valid turno list item", () => {
      const validItem = {
        task: "Pulizia cucina",
        assegnatarioCorrente: { id: "u1", username: "mario" },
        dataProssimaPulizia: "2026-05-25T10:30:00Z",
      };

      const result = TurnoListItemSchema.safeParse(validItem);
      expect(result.success).toBe(true);
    });

    it("rejects missing assegnatarioCorrente", () => {
      const invalidItem = {
        task: "Pulizia cucina",
        dataProssimaPulizia: "2026-05-25T10:30:00Z",
      };

      const result = TurnoListItemSchema.safeParse(invalidItem);
      expect(result.success).toBe(false);
    });
  });
});

