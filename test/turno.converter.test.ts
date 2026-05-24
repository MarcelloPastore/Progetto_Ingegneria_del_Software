import { describe, it, expect } from "vitest";
import { TurnoConverter } from "../src/dto/converter/TurnoConverter";

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
});

