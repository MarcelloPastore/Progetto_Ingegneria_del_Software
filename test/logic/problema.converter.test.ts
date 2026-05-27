/**
 * LOGIC TESTS — ProblemaConverter
 */
import { describe, it, expect } from "vitest";
import { ProblemaConverter } from "../../src/dto/converter/ProblemaConverter";

const converter = new ProblemaConverter();

describe("ProblemaConverter", () => {
  it("toDto uses relations when present", () => {
    const dto = converter.toDto({
      id: "p1",
      nome: "Rubinetto",
      descrizione: "Perde acqua",
      priorita: "Urgente",
      stato: "Segnalato",
      segnalataDa: "u1",
      segnalataDaRel: { id: "u1", username: "mario" },
      assegnatario: "u2",
      assegnatarioRel: { id: "u2", username: "luigi" },
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
      dataRisoluzione: null,
    });

    expect(dto.segnalataDa).toEqual({ id: "u1", username: "mario" });
    expect(dto.assegnatario).toEqual({ id: "u2", username: "luigi" });
    expect(dto.dataCreazione).toBe("2026-05-18T10:30:00.000Z");
    expect(dto.dataRisoluzione).toBeNull();
  });

  it("toListItemDto falls back to id when assegnatarioRel is missing", () => {
    const dto = converter.toListItemDto({
      id: "p2",
      nome: "Lampadina",
      descrizione: "Bruciata",
      priorita: "Bassa",
      stato: "Assegnato",
      segnalataDa: "u1",
      segnalataDaRel: { id: "u1", username: "mario" },
      assegnatario: "u9",
      assegnatarioRel: null,
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
      dataRisoluzione: null,
    });

    expect(dto.assegnatario).toEqual({ id: "u9", username: "" });
    expect(dto.stato).toBe("Assegnato");
    expect(dto.priorita).toBe("Bassa");
  });
});

