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
  idCreatore: "u1",
};

describe("TurnoService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
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
});
