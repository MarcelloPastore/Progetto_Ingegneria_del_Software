/**
 * LOGIC TESTS — SpesaConverter
 *
 * Testiamo:
 * - serializzazione date (datetime e date-only)
 * - calcolo cadenzaMesi da cadenzaGiorni (arrotondamento e fallback)
 * - fallback partecipanti: da quote (se presenti) oppure da partecipantiRel / partecipanti
 */
import { describe, it, expect } from "vitest";
import { SpesaConverter } from "../../src/dto/converter/SpesaConverter";

const converter = new SpesaConverter();

describe("SpesaConverter", () => {
  it("toSpesaListItemDto serializes basic info", () => {
    const dto = converter.toSpesaListItemDto({
      id: "s1",
      descrizione: "Detersivo",
      importo: 12.5,
      anticipataDa: null,
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
      rotazioneAttiva: false,
    } as any);

    expect(dto).toEqual({
      descrizione: "Detersivo",
      dataCreazione: "2026-05-18T10:30:00.000Z",
      anticipataDa: null,
      importoTotale: 12.5,
    });
  });

  it("toSpesaDto uses quote list to compute partecipanti + saldato", () => {
    const dto = converter.toSpesaDto({
      id: "s1",
      descrizione: "Affitto",
      importo: 100,
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: "u1",
      anticipataDaRel: { id: "u1", username: "mario" },
      scadenzaRel: {
        dataScadenza: new Date("2026-06-01T00:00:00.000Z"),
        isRicorrente: true,
        cadenzaGiorni: 30,
      },
      quote: [
        {
          id: "q1",
          quota: 50,
          dataPagamento: new Date("2026-05-19T10:00:00.000Z"),
          idUtente: "u1",
          utenteRel: { id: "u1", username: "mario" },
        },
        {
          id: "q2",
          quota: 50,
          dataPagamento: null,
          idUtente: "u2",
          utenteRel: { id: "u2", username: "luigi" },
        },
      ],
    } as any);

    expect(dto.dataScadenza).toBe("2026-06-01");
    expect(dto.isRicorrente).toBe(true);
    expect(dto.cadenzaMesi).toBe(1);
    expect(dto.partecipanti).toEqual([
      { utente: { id: "u1", username: "mario" }, saldato: true },
      { utente: { id: "u2", username: "luigi" }, saldato: false },
    ]);
  });

  it("toSpesaDto falls back to partecipantiRel when quotes are absent", () => {
    const dto = converter.toSpesaDto({
      id: "s2",
      descrizione: "Internet",
      importo: 30,
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: null,
      scadenzaRel: null,
      quote: [],
      partecipantiRel: [
        { id: "u1", username: "mario" },
        { id: "u2", username: "luigi" },
      ],
    } as any);

    expect(dto.partecipanti).toEqual([
      { utente: { id: "u1", username: "mario" }, saldato: false },
      { utente: { id: "u2", username: "luigi" }, saldato: false },
    ]);
  });

  it("toSpesaDto returns cadenzaMesi=null when cadenzaGiorni is missing/invalid", () => {
    const dto = converter.toSpesaDto({
      id: "s3",
      descrizione: "Spesa una tantum",
      importo: 10,
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      scadenzaRel: { dataScadenza: new Date("2026-06-01"), isRicorrente: true },
      quote: [],
      partecipanti: ["u1"],
    } as any);

    expect(dto.cadenzaMesi).toBeNull();
  });
});

