import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  createTurno: vi.fn(),
  updateTurno: vi.fn(),
  findTurnoByIdOrThrow: vi.fn(),
  findTurniByCasa: vi.fn(),
  deleteTurno: vi.fn(),
  getMembriCasaIds: vi.fn(),
}));

vi.mock("../src/repository/TurnoRepository", () => ({
  TurnoRepository: class {
    createTurno = mocks.createTurno;
    updateTurno = mocks.updateTurno;
    findTurnoByIdOrThrow = mocks.findTurnoByIdOrThrow;
    findTurniByCasa = mocks.findTurniByCasa;
    deleteTurno = mocks.deleteTurno;
  },
}));

vi.mock("../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    getMembriCasaIds = mocks.getMembriCasaIds;
  },
}));

import { TurnoService } from "../src/service/TurnoService";

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
};

describe("TurnoService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("creaTurno builds ordineRotazione and persists cadenzaGiorni", async () => {
    mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2", "u3"]);
    mocks.createTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.creaTurno("c1", {
      task: "Pulizia cucina",
      cadenzaGiorni: 7,
      assegnatario: "u1",
      rotazioneTurno: true,
    });

    expect(mocks.createTurno).toHaveBeenCalledTimes(1);
    const dataArg = mocks.createTurno.mock.calls[0][0];
    expect(dataArg.cadenzaGiorni).toBe(7);
    expect(dataArg.ordineRotazione[0]).toBe("u1");
    expect(dataArg.ordineRotazione).toEqual(
      expect.arrayContaining(["u1", "u2", "u3"]),
    );
  });

  it("modificaTurno updates fields and order", async () => {
    mocks.findTurnoByIdOrThrow.mockResolvedValue({
      ...baseTurno,
      ordineRotazione: ["u1"],
    });
    mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
    mocks.updateTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.modificaTurno("c1", "t1", {
      task: "Pulizia bagno",
      cadenzaGiorni: 14,
      rotazioneTurno: false,
    });

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

  it("completaTurno advances rotation", async () => {
    mocks.findTurnoByIdOrThrow.mockResolvedValue({
      ...baseTurno,
      ordineRotazione: ["u1", "u2"],
      indiceRotazioneCorrente: 0,
      assegnatarioCorrente: "u1",
    });
    mocks.updateTurno.mockResolvedValue({ ...baseTurno });

    const service = new TurnoService();
    await service.completaTurno("c1", "t1");

    expect(mocks.updateTurno).toHaveBeenCalledWith(
      "t1",
      expect.objectContaining({
        indiceRotazioneCorrente: 1,
        assegnatarioCorrente: "u2",
        dataUltimaPulizia: expect.any(Date),
      }),
    );
  });
});
