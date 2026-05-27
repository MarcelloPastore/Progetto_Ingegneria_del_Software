/**
 * BOUNDARIES / EDGE CASES — SpesaService
 *
 * Focus:
 * - suddivisione in quote con importi molto piccoli e/o con resto in centesimi
 * - garantire: somma quote === importo e quote con massimo 2 decimali (centesimi)
 */
import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  createSpesa: vi.fn(),
}));

vi.mock("../../src/repository/SpesaRepository", () => ({
  SpesaRepository: class {
    constructor() {
      Object.assign(this as any, {
        createSpesa: mocks.createSpesa,
      });
    }
  },
}));

import { SpesaService } from "../../src/service/SpesaService";

describe("SpesaService - boundaries", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("splits 0.01 among 3 partecipanti: sum matches and values are cent-based", async () => {
    mocks.createSpesa.mockResolvedValue({
      id: "s1",
      descrizione: "Microspesa",
      importo: 0.01,
      dataCreazione: new Date(),
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: null,
      quote: [],
      partecipantiRel: [],
      scadenzaRel: null,
    });

    const service = new SpesaService();
    await service.addSpesa(
      "c1",
      {
        descrizione: "Microspesa",
        importo: 0.01,
        partecipanti: ["u1", "u2", "u3"],
        isRicorrente: false,
      },
      "u1",
    );

    const [arg] = mocks.createSpesa.mock.calls[0] as [
      { quote: Array<{ idUtente: string; quota: number }> },
    ];

    expect(arg.quote).toHaveLength(3);

    const sum = arg.quote.reduce((acc, q) => acc + q.quota, 0);
    expect(sum).toBeCloseTo(0.01, 6);

    for (const q of arg.quote) {
      expect(Number.isInteger(Math.round(q.quota * 100))).toBe(true);
    }
  });

  it("splits 10.01 among 3 partecipanti: two get +1 cent", async () => {
    mocks.createSpesa.mockResolvedValue({
      id: "s2",
      descrizione: "Spesa",
      importo: 10.01,
      dataCreazione: new Date(),
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: null,
      quote: [],
      partecipantiRel: [],
      scadenzaRel: null,
    });

    const service = new SpesaService();
    await service.addSpesa(
      "c1",
      {
        descrizione: "Spesa",
        importo: 10.01,
        partecipanti: ["u1", "u2", "u3"],
        isRicorrente: false,
      },
      "u1",
    );

    const [arg] = mocks.createSpesa.mock.calls[0] as [
      { quote: Array<{ idUtente: string; quota: number }> },
    ];

    const amounts = arg.quote.map((q) => q.quota);
    const sum = amounts.reduce((acc, v) => acc + v, 0);

    expect(sum).toBeCloseTo(10.01, 6);

    // in centesimi: [334, 334, 333] in qualche ordine
    const cents = amounts.map((v) => Math.round(v * 100)).sort((a, b) => a - b);
    expect(cents).toEqual([333, 334, 334]);
  });
});

