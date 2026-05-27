/**
 * BOUNDARIES / EDGE CASES — ProblemaService
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { Priorita, Stato } from "@prisma/client";

const mocks = vi.hoisted(() => ({
  findProblemaByIdOrThrow: vi.fn(),
  updateProblema: vi.fn(),
}));

vi.mock("../../src/repository/ProblemaRepository", () => ({
  ProblemaRepository: class {
    constructor() {
      Object.assign(this as any, {
        findProblemaByIdOrThrow: mocks.findProblemaByIdOrThrow,
        updateProblema: mocks.updateProblema,
      });
    }
  },
}));

import { ProblemaService } from "../../src/service/ProblemaService";

describe("ProblemaService - boundaries", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  const baseProblema = {
    id: "p1",
    idCasa: "c1",
    nome: "Rubinetto",
    descrizione: "Perde acqua",
    priorita: Priorita.Media,
    stato: Stato.Segnalato,
    segnalataDa: "u1",
    segnalataDaRel: { id: "u1", username: "mario" },
    assegnatario: null,
    assegnatarioRel: null,
    dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
    dataRisoluzione: null,
  };

  it("aggiornaStato sets dataRisoluzione when Risolto, and clears it for non-Risolto", async () => {
    mocks.findProblemaByIdOrThrow.mockResolvedValue(baseProblema);

    const now = new Date("2026-05-20T10:00:00.000Z");
    vi.setSystemTime(now);

    mocks.updateProblema.mockResolvedValue({
      ...baseProblema,
      stato: Stato.Risolto,
      dataRisoluzione: now,
    });

    const service = new ProblemaService();
    await service.aggiornaStato("c1", "p1", { stato: Stato.Risolto });

    expect(mocks.updateProblema).toHaveBeenCalledWith(
      "p1",
      expect.objectContaining({
        stato: Stato.Risolto,
        dataRisoluzione: expect.any(Date),
      }),
    );

    mocks.updateProblema.mockClear();

    mocks.updateProblema.mockResolvedValue({
      ...baseProblema,
      stato: Stato.Segnalato,
      dataRisoluzione: null,
    });

    await service.aggiornaStato("c1", "p1", { stato: Stato.Segnalato });

    expect(mocks.updateProblema).toHaveBeenCalledWith(
      "p1",
      expect.objectContaining({
        stato: Stato.Segnalato,
        dataRisoluzione: null,
      }),
    );

    vi.useRealTimers();
  });

  it("assegnaProblema treats missing idUtente (undefined) as unassign", async () => {
    mocks.findProblemaByIdOrThrow.mockResolvedValue(baseProblema);
    mocks.updateProblema.mockResolvedValue(baseProblema);

    const service = new ProblemaService();
    // @ts-ignore - boundary: simulate missing property at runtime
    await service.assegnaProblema("c1", "p1", {});

    expect(mocks.updateProblema).toHaveBeenCalledWith(
      "p1",
      expect.objectContaining({ assegnatario: null, stato: Stato.Segnalato }),
    );

    vi.useRealTimers();
  });
});

