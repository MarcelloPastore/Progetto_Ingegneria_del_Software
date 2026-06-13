/*
import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  createTurno: vi.fn(),
  updateTurno: vi.fn(),
  findTurnoByIdOrThrow: vi.fn(),
  findTurniByCasa: vi.fn(),
  deleteTurno: vi.fn(),
  getMembriCasaIds: vi.fn(),
}));

vi.mock("../../src/repository/TurnoRepository", () => ({
  TurnoRepository: class {
    constructor() {
      Object.assign(this as any, {
        createTurno: mocks.createTurno,
        updateTurno: mocks.updateTurno,
        findTurnoByIdOrThrow: mocks.findTurnoByIdOrThrow,
        findTurniByCasa: mocks.findTurniByCasa,
        deleteTurno: mocks.deleteTurno,
      });
    }
  },
}));

vi.mock("../../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    constructor() {
      Object.assign(this as any, {
        getMembriCasaIds: mocks.getMembriCasaIds,
      });
    }
  },
}));

import { TurnoService } from "../../src/service/TurnoService";

const baseTurno = {
  id: "t1",
  task: "Pulizia cucina",
  cadenzaGiorni: 7,
  rotazioneAttiva: true,
  assegnatarioCorrente: "u1",
  assegnatarioCorrenteRel: { id: "u1", username: "mario" },
  ordineRotazione: ["u1", "u2"],
  indiceRotazioneCorrente: 0,
  dataUltimaPulizia: null,
  dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
  idCreatore: "u1",
};

describe("TurnoService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("creaTurno builds ordineRotazione and persists cadenzaGiorni", async () => {
    mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2", "u3"]);
    mocks.createTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.creaTurno(
      "c1",
      {
        task: "Pulizia cucina",
        cadenzaGiorni: 7,
        assegnatario: "u1",
        rotazioneTurno: true,
      },
      "u1",
    );

    expect(mocks.createTurno).toHaveBeenCalledTimes(1);
    const [dataArg] = mocks.createTurno.mock.calls[0] as [
      { idCreatore: string; cadenzaGiorni: number; ordineRotazione: string[] },
    ];
    expect(dataArg.idCreatore).toBe("u1");
    expect(dataArg.cadenzaGiorni).toBe(7);
    expect(dataArg.ordineRotazione[0]).toBe("u1");
    expect(dataArg.ordineRotazione).toEqual(
      expect.arrayContaining(["u1", "u2", "u3"]),
    );
    expect(mocks.getMembriCasaIds).toHaveBeenCalledTimes(1);
  });

  it("creaTurno without rotation does not fetch members and uses single-element order", async () => {
    mocks.createTurno.mockResolvedValue({ ...baseTurno, rotazioneAttiva: false });

    const service = new TurnoService();
    await service.creaTurno(
      "c1",
      {
        task: "Pulizia cucina",
        cadenzaGiorni: 7,
        assegnatario: "u1",
        rotazioneTurno: false,
      },
      "u1",
    );

    expect(mocks.getMembriCasaIds).not.toHaveBeenCalled();
    const [dataArg] = mocks.createTurno.mock.calls[0] as [
      { ordineRotazione: string[]; rotazioneAttiva: boolean },
    ];
    expect(dataArg.rotazioneAttiva).toBe(false);
    expect(dataArg.ordineRotazione).toEqual(["u1"]);
  });

  it("modificaTurno updates fields and order", async () => {
    mocks.findTurnoByIdOrThrow.mockResolvedValue({
      ...baseTurno,
      ordineRotazione: ["u1"],
    });
    mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
    mocks.updateTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.modificaTurno(
      "c1",
      "t1",
      {
        task: "Pulizia bagno",
        cadenzaGiorni: 14,
        rotazioneTurno: false,
      },
      "u1",
    );

    expect(mocks.updateTurno).toHaveBeenCalledWith(
      "t1",
      expect.objectContaining({
        task: "Pulizia bagno",
        cadenzaGiorni: 14,
        rotazioneAttiva: false,
        ordineRotazione: ["u1", "u2"],
      }),
    );
  });

  it("modificaTurno with empty dto still refreshes ordineRotazione only", async () => {
    mocks.findTurnoByIdOrThrow.mockResolvedValue({
      ...baseTurno,
      ordineRotazione: ["u1"],
    });
    mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
    mocks.updateTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.modificaTurno("c1", "t1", {}, "u1");

    expect(mocks.updateTurno).toHaveBeenCalledWith(
      "t1",
      {
        ordineRotazione: ["u1", "u2"],
      },
    );
  });

  it("completaTurno advances rotation", async () => {
    mocks.findTurnoByIdOrThrow.mockResolvedValue({
      ...baseTurno,
      ordineRotazione: ["u1", "u2"],
      indiceRotazioneCorrente: 1,
      assegnatarioCorrente: "u2",
    });
    mocks.updateTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.completaTurno("c1", "t1", "u2");

    expect(mocks.updateTurno).toHaveBeenCalledTimes(1);
    const [, updateArg] = mocks.updateTurno.mock.calls[0] as [
      string,
      {
        indiceRotazioneCorrente: number;
        assegnatarioCorrente: string;
        dataUltimaPulizia: Date;
      },
    ];
    expect(updateArg.indiceRotazioneCorrente).toBe(0);
    expect(updateArg.assegnatarioCorrente).toBe("u1");
    expect(updateArg.dataUltimaPulizia).toBeInstanceOf(Date);
  });

  it("getAllTurni maps repository results to list items", async () => {
    mocks.findTurniByCasa.mockResolvedValue([
      {
        ...baseTurno,
        task: "Pulizia cucina",
        cadenzaGiorni: 7,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      },
    ]);

    const service = new TurnoService();
    const items = await service.getAllTurni("c1");

    expect(items).toHaveLength(1);
    expect(items[0]).toEqual(
      expect.objectContaining({
        id: "t1",
        task: "Pulizia cucina",
        assegnatario: { id: "u1", username: "mario" },
        dataProssimaPulizia: "2026-05-25T00:00:00.000Z",
      }),
    );
  });
});

 */
