/**
 * LOGIC TESTS — TurnoConverter
 *
 * Scopo:
 * - verificare il mapping entity/repository → DTO esposti dalle API
 * - garantire default e fallback coerenti quando arrivano dati null/undefined o incompleti
 *
 * Perché è utile:
 * - il converter è usato da service/controller: un bug qui si propaga ovunque (risposte errate, date sbagliate, campi mancanti)
 * - protegge da regressioni quando cambiano i modelli Prisma o i DTO
 *
 * Cosa indica un fallimento:
 * - regressione nel calcolo della `dataProssimaPulizia`
 * - perdita di fallback su assegnatario/ordine rotazione/valori default
 */
import { describe, it, expect } from "vitest";
import { TurnoConverter } from "../../src/dto/converter/TurnoConverter";

const converter = new TurnoConverter();

describe("TurnoConverter", () => {
  it("serializes ordineRotazione and computes next date", () => {
    const baseDate = new Date("2026-05-18T00:00:00.000Z");
    const dto = converter.toDto({
      id: "t1",
      task: "Pulizia cucina",
      cadenzaGiorni: 7,
      rotazioneAttiva: true,
      assegnatarioCorrente: "u1",
      assegnatarioCorrenteRel: { id: "u1", username: "mario" },
      ordineRotazione: ["u1", "u2"],
      indiceRotazioneCorrente: 0,
      dataUltimaPulizia: null,
      dataCreazione: baseDate,
    });

    expect(dto.ordineRotazione).toEqual(["u1", "u2"]);
    expect(dto.cadenzaGiorni).toBe(7);
    expect(dto.dataProssimaPulizia).toBe("2026-05-25T00:00:00.000Z");
    expect(dto.dataCreazione).toBe("2026-05-18T00:00:00.000Z");
    expect(dto.dataUltimaPulizia).toBeNull();
  });

  it("falls back to assegnatarioCorrente when relation is missing", () => {
    const dto = converter.toDto({
      id: "t2",
      task: "Pulizia bagno",
      cadenzaGiorni: 3,
      rotazioneAttiva: true,
      assegnatarioCorrente: "u9",
      ordineRotazione: [],
      indiceRotazioneCorrente: 0,
      dataUltimaPulizia: null,
      dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
    });

    expect(dto.assegnatario.id).toBe("u9");
    expect(dto.assegnatario.username).toBe("");
  });

  it("defaults indiceRotazioneCorrente and cadenzaGiorni when invalid", () => {
    const dto = converter.toDto({
      id: "t3",
      task: "Pulizia finestre",
      cadenzaGiorni: 0,
      rotazioneAttiva: false,
      assegnatarioCorrente: "u1",
      assegnatarioCorrenteRel: { id: "u1", username: "mario" },
      // @ts-expect-error Simulazione di dati non validi
      ordineRotazione: "not-an-array",
      indiceRotazioneCorrente: undefined,
      dataUltimaPulizia: null,
      dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
    });

    expect(dto.indiceRotazioneCorrente).toBe(0);
    expect(dto.cadenzaGiorni).toBe(1);
    expect(dto.ordineRotazione).toEqual([]);
  });

  it("toListItemDto uses dataUltimaPulizia as reference when present", () => {
    const creation = new Date("2026-05-01T00:00:00.000Z");
    const lastDone = new Date("2026-05-18T00:00:00.000Z");

    const listItem = converter.toListItemDto({
      id: "t4",
      task: "Pulizia scale",
      cadenzaGiorni: 7,
      rotazioneAttiva: true,
      assegnatarioCorrente: "u1",
      assegnatarioCorrenteRel: { id: "u1", username: "mario" },
      ordineRotazione: ["u1"],
      indiceRotazioneCorrente: 0,
      dataUltimaPulizia: lastDone,
      dataCreazione: creation,
    });

    expect(listItem.id).toBe("t4");
    expect(listItem.task).toBe("Pulizia scale");
    expect(listItem.assegnatario).toEqual({ id: "u1", username: "mario" });
    expect(listItem.dataProssimaPulizia).toBe("2026-05-25T00:00:00.000Z");
  });

  it("toListItemDto defaults cadenzaGiorni to 1 when missing/invalid", () => {
    const baseDate = new Date("2026-05-18T00:00:00.000Z");

    const listItem = converter.toListItemDto({
      id: "t5",
      task: "Pulizia balcone",
      cadenzaGiorni: 0,
      rotazioneAttiva: true,
      assegnatarioCorrente: "u1",
      assegnatarioCorrenteRel: { id: "u1", username: "mario" },
      ordineRotazione: ["u1"],
      indiceRotazioneCorrente: 0,
      dataUltimaPulizia: null,
      dataCreazione: baseDate,
    });

    expect(listItem.dataProssimaPulizia).toBe("2026-05-19T00:00:00.000Z");
  });

  it("toDto falls back to empty assignee id when both relation and assegnatarioCorrente are missing", () => {
    const dto = converter.toDto({
      id: "t6",
      task: "Pulizia garage",
      cadenzaGiorni: 2,
      rotazioneAttiva: false,
      assegnatarioCorrente: null,
      assegnatarioCorrenteRel: null,
      ordineRotazione: null,
      indiceRotazioneCorrente: null,
      dataUltimaPulizia: null,
      dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
    });

    expect(dto.assegnatario).toEqual({ id: "", username: "" });
    expect(dto.ordineRotazione).toEqual([]);
    expect(dto.indiceRotazioneCorrente).toBe(0);
  });
});
