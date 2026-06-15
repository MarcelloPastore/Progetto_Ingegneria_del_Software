/**
 * DEFECT / REGRESSION TESTS — TurnoService
 *
 * Scopo:
 * - testare i comportamenti "critici" e l'error handling (es. autorizzazioni)
 * - proteggere da regressioni su bug già incontrati o potenziali
 *
 * Caratteristiche:
 * - repository mockati: si testa la logica del service, non il DB
 * - focus su: eccezioni, messaggi, casi limite che in passato hanno causato difetti
 *
 * Cosa indica un fallimento:
 * - possibile regressione di sicurezza (es. bypass permessi)
 * - cambiamento non voluto nei messaggi/condizioni di errore
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { Ruolo } from "@prisma/client";
import { ForbiddenError } from "../../src/errors/httpErrors";

const mocks = vi.hoisted(() => ({
  updateTurno: vi.fn(),
  findTurnoByIdOrThrow: vi.fn(),
}));

vi.mock("../../src/repository/TurnoRepository", () => ({
  TurnoRepository: class {
    constructor() {
      Object.assign(this as any, {
        updateTurno: mocks.updateTurno,
        findTurnoByIdOrThrow: mocks.findTurnoByIdOrThrow,
      });
    }
  },
}));

const casaMocks = vi.hoisted(() => ({
  findMembroCasaByCasaAndUtenteOrThrow: vi.fn(),
  getMembriCasaIds: vi.fn().mockResolvedValue(["u1", "u2", "u3"]),
}));

vi.mock("../../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    findMembroCasaByCasaAndUtenteOrThrow = casaMocks.findMembroCasaByCasaAndUtenteOrThrow;
    getMembriCasaIds = casaMocks.getMembriCasaIds;
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
  ordineRotazione: ["u1", "u2", "u3"],
  indiceRotazioneCorrente: 0,
  dataUltimaPulizia: null,
  dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
  idCreatore: "u1",
};

describe("TurnoService - Defect Tests (Error Handling)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("Authorization errors", () => {
    it("throws ForbiddenError when non-creator tries to modify turno", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue(baseTurno);

      const service = new TurnoService();

      await expect(
        service.modificaTurno("c1", "t1", { task: "New task" }, "u2"),
      ).rejects.toThrow(ForbiddenError);
      await expect(
        service.modificaTurno("c1", "t1", { task: "New task" }, "u2"),
      ).rejects.toThrow("Solo l'idCreatore");
    });

    it("throws ForbiddenError when non-creator tries to delete turno", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue(baseTurno);
      casaMocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValue({ ruolo: Ruolo.Inquilino });

      const service = new TurnoService();

      await expect(service.eliminaTurno("c1", "t1", "u2")).rejects.toThrow(
        ForbiddenError,
      );
      await expect(service.eliminaTurno("c1", "t1", "u2")).rejects.toThrow(
        "Solo l'idCreatore",
      );
    });

    it("throws ForbiddenError when non-assignee tries to complete turno", async () => {
      const turnoWithAssignee = {
        ...baseTurno,
        assegnatarioCorrente: "u2",
      };
      mocks.findTurnoByIdOrThrow.mockResolvedValue(turnoWithAssignee);

      const service = new TurnoService();

      await expect(
        service.completaTurno("c1", "t1", "u1"),
      ).rejects.toThrow(ForbiddenError);
      await expect(
        service.completaTurno("c1", "t1", "u1"),
      ).rejects.toThrow("Solo l'assegnatario corrente");
    });

    it("allows creator to complete turno as assignee", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue(baseTurno);
      mocks.updateTurno.mockResolvedValue({
        ...baseTurno,
        dataUltimaPulizia: new Date(),
        indiceRotazioneCorrente: 1,
        assegnatarioCorrente: "u2",
      });

      const service = new TurnoService();

      const result = await service.completaTurno("c1", "t1", "u1");
      expect(result).toBeDefined();
      expect(mocks.updateTurno).toHaveBeenCalled();
    });
  });
});

