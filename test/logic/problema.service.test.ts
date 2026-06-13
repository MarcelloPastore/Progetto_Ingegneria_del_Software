/**
 * LOGIC TESTS — ProblemaService
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { Priorita, Ruolo, Stato } from "@prisma/client";

const mocks = vi.hoisted(() => ({
  findProblemiByCasa: vi.fn(),
  findProblemiNonRisolti: vi.fn(),
  findProblemaByIdOrThrow: vi.fn(),
  createProblema: vi.fn(),
  updateProblema: vi.fn(),
  deleteProblema: vi.fn(),
}));

vi.mock("../../src/repository/ProblemaRepository", () => ({
  ProblemaRepository: class {
    constructor() {
      Object.assign(this as any, {
        findProblemiByCasa: mocks.findProblemiByCasa,
        findProblemiNonRisolti: mocks.findProblemiNonRisolti,
        findProblemaByIdOrThrow: mocks.findProblemaByIdOrThrow,
        createProblema: mocks.createProblema,
        updateProblema: mocks.updateProblema,
        deleteProblema: mocks.deleteProblema,
      });
    }
  },
}));

import { ProblemaService } from "../../src/service/ProblemaService";

describe("ProblemaService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
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

  it("segnalaProblema passes priorita only if provided", async () => {
    mocks.createProblema.mockResolvedValue(baseProblema);

    const service = new ProblemaService();
    await service.segnalaProblema(
      "c1",
      { nome: "Rubinetto", descrizione: "Perde acqua" },
      "u1",
    );

    expect(mocks.createProblema).toHaveBeenCalledWith(
      expect.not.objectContaining({ priorita: expect.anything() }),
    );

    mocks.createProblema.mockClear();

    await service.segnalaProblema(
      "c1",
      {
        nome: "Rubinetto",
        descrizione: "Perde acqua",
        priorita: Priorita.Urgente,
      },
      "u1",
    );

    expect(mocks.createProblema).toHaveBeenCalledWith(
      expect.objectContaining({ priorita: Priorita.Urgente }),
    );
  });

  it("autoassegnaProblema sets stato=Assegnato and dataRisoluzione=null", async () => {
    mocks.findProblemaByIdOrThrow.mockResolvedValue(baseProblema);
    mocks.updateProblema.mockResolvedValue({
      ...baseProblema,
      stato: Stato.Assegnato,
      assegnatario: "u2",
      assegnatarioRel: { id: "u2", username: "luigi" },
    });

    const service = new ProblemaService();
    await service.autoassegnaProblema("c1", "p1", "u2");

    expect(mocks.updateProblema).toHaveBeenCalledWith(
      "p1",
      expect.objectContaining({
        assegnatario: "u2",
        stato: Stato.Assegnato,
        dataRisoluzione: null,
      }),
    );
  });

  it("modificaProblema updates only the provided fields", async () => {
    mocks.findProblemaByIdOrThrow.mockResolvedValue(baseProblema);
    mocks.updateProblema.mockResolvedValue({
      ...baseProblema,
      nome: "Rubinetto cucina",
      priorita: Priorita.Urgente,
    });

    const service = new ProblemaService();
    await service.modificaProblema(
      "c1",
      "p1",
      {
        nome: "Rubinetto cucina",
        priorita: Priorita.Urgente,
      },
      "u1",
      Ruolo.Inquilino,
    );

    expect(mocks.updateProblema).toHaveBeenCalledWith("p1", {
      nome: "Rubinetto cucina",
      priorita: Priorita.Urgente,
    });
  });

  it("rinunciaProblema clears the current assignee", async () => {
    mocks.findProblemaByIdOrThrow.mockResolvedValue({
      ...baseProblema,
      stato: Stato.Assegnato,
      assegnatario: "u2",
    });
    mocks.updateProblema.mockResolvedValue(baseProblema);

    const service = new ProblemaService();
    await service.rinunciaProblema("c1", "p1", "u2");

    expect(mocks.updateProblema).toHaveBeenCalledWith("p1", {
      assegnatario: null,
      stato: Stato.Segnalato,
      dataRisoluzione: null,
    });
  });

  it("assegnaProblema sets stato based on idUtente (null => Segnalato)", async () => {
    mocks.findProblemaByIdOrThrow.mockResolvedValue(baseProblema);
    mocks.updateProblema.mockResolvedValue(baseProblema);

    const service = new ProblemaService();
    await service.assegnaProblema("c1", "p1", { idUtente: null });

    expect(mocks.updateProblema).toHaveBeenCalledWith(
      "p1",
      expect.objectContaining({ assegnatario: null, stato: Stato.Segnalato }),
    );

    mocks.updateProblema.mockClear();

    await service.assegnaProblema("c1", "p1", { idUtente: "u2" });
    expect(mocks.updateProblema).toHaveBeenCalledWith(
      "p1",
      expect.objectContaining({ assegnatario: "u2", stato: Stato.Assegnato }),
    );
  });

  it("aggiornaStato sets dataRisoluzione when Risolto", async () => {
    const now = new Date("2026-05-20T10:00:00.000Z");
    vi.setSystemTime(now);

    mocks.findProblemaByIdOrThrow.mockResolvedValue(baseProblema);
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

    vi.useRealTimers();
  });
});
