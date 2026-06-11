/**
 * BOUNDARIES / EDGE CASES — TurnoConverter + TurnoService
 *
 * Scopo:
 * - verificare casi al limite (min/max, array vuoti, transizioni mese/anno, leap year, ecc.)
 * - assicurare che la logica continui a funzionare con input "strani ma validi"
 *
 * Perché è utile:
 * - molti bug emergono solo ai limiti (indice fuori range, date su fine mese, null/undefined)
 * - documenta esplicitamente decisioni di dominio (fallback a 1 giorno, ordine rotazione, wrap-around)
 *
 * Nota:
 * - la parte TurnoService usa mock dei repository per isolare i comportamenti.
 */
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
import { TurnoConverter } from "../../src/dto/converter/TurnoConverter";

const converter = new TurnoConverter();

describe("TurnoConverter - Boundary and Edge Cases", () => {
  describe("Cadenza Giorni boundaries", () => {
    it("handles cadenzaGiorni minimum value (1 day)", () => {
      const baseDate = new Date("2026-05-18T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 1);

      const dto = converter.toDto({
        id: "t1",
        task: "Daily task",
        cadenzaGiorni: 1,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(dto.cadenzaGiorni).toBe(1);
      expect(dto.dataProssimaPulizia).toBe(nextDate.toISOString());
    });

    it("handles cadenzaGiorni year boundary (365 days)", () => {
      const baseDate = new Date("2026-05-18T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 365);

      const dto = converter.toDto({
        id: "t1",
        task: "Yearly task",
        cadenzaGiorni: 365,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(dto.dataProssimaPulizia).toBe(nextDate.toISOString());
    });

    it("handles cadenzaGiorni zero (falls back to 1)", () => {
      const baseDate = new Date("2026-05-18T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 1);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 0,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(dto.cadenzaGiorni).toBe(1);
      expect(dto.dataProssimaPulizia).toBe(nextDate.toISOString());
    });

    it("handles null cadenzaGiorni (falls back to 1)", () => {
      const baseDate = new Date("2026-05-18T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 1);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: null,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(dto.cadenzaGiorni).toBe(1);
    });

    it("handles very large cadenzaGiorni", () => {
      const baseDate = new Date("2026-01-01T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 1000);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 1000,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(dto.dataProssimaPulizia).toBe(nextDate.toISOString());
    });
  });

  describe("Month and year transitions", () => {
    it("handles transition across month boundary", () => {
      // 31 May + 5 days = 5 June
      const baseDate = new Date("2026-05-31T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 5);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 5,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(new Date(dto.dataProssimaPulizia).getMonth()).toBe(5); // June
      expect(new Date(dto.dataProssimaPulizia).getDate()).toBe(5);
    });

    it("handles transition across year boundary", () => {
      // 31 December 2026 + 7 days
      const baseDate = new Date("2026-12-31T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 7);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(new Date(dto.dataProssimaPulizia).getFullYear()).toBe(2027);
      expect(new Date(dto.dataProssimaPulizia).getMonth()).toBe(0); // January
    });

    it("handles leap year February boundary", () => {
      // 2024 is a leap year: 29 February + 1 day
      const baseDate = new Date("2024-02-29T00:00:00.000Z");
      const nextDate = new Date(baseDate);
      nextDate.setDate(nextDate.getDate() + 1);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 1,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        assegnatarioCorrenteRel: { id: "u1", username: "mario" },
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(new Date(dto.dataProssimaPulizia).getMonth()).toBe(2); // March
      expect(new Date(dto.dataProssimaPulizia).getDate()).toBe(1);
    });
  });

  describe("Rotation array boundaries", () => {
    it("handles ordineRotazione with single member", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.ordineRotazione).toEqual(["u1"]);
      expect(dto.indiceRotazioneCorrente).toBe(0);
    });

    it("handles empty ordineRotazione array", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: [],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.ordineRotazione).toEqual([]);
    });

    it("handles very large ordineRotazione", () => {
      const largeArray = Array.from({ length: 100 }, (_, i) => `u${i + 1}`);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: largeArray,
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.ordineRotazione).toHaveLength(100);
    });

    it("handles null ordineRotazione (falls back to empty array)", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: null,
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.ordineRotazione).toEqual([]);
    });
  });

  describe("Index rotation boundaries", () => {
    it("handles index at zero", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1", "u2", "u3"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.indiceRotazioneCorrente).toBe(0);
    });

    it("handles index at last position", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u3",
        ordineRotazione: ["u1", "u2", "u3"],
        indiceRotazioneCorrente: 2,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.indiceRotazioneCorrente).toBe(2);
    });

    it("handles very large index value", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 999,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.indiceRotazioneCorrente).toBe(999);
    });

    it("handles null index (falls back to 0)", () => {
      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1", "u2"],
        indiceRotazioneCorrente: null,
        dataUltimaPulizia: null,
        dataCreazione: new Date("2026-05-18T00:00:00.000Z"),
      });

      expect(dto.indiceRotazioneCorrente).toBe(0);
    });
  });

  describe("Data reference boundaries", () => {
    it("uses dataUltimaPulizia when available (ignoring dataCreazione)", () => {
      const creationDate = new Date("2026-05-01T00:00:00.000Z");
      const lastCleanDate = new Date("2026-05-18T00:00:00.000Z");
      const expectedNextDate = new Date(lastCleanDate);
      expectedNextDate.setDate(expectedNextDate.getDate() + 7);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: lastCleanDate,
        dataCreazione: creationDate,
      });

      expect(dto.dataProssimaPulizia).toBe(expectedNextDate.toISOString());
    });

    it("uses dataCreazione as fallback when dataUltimaPulizia is null", () => {
      const creationDate = new Date("2026-05-01T00:00:00.000Z");
      const expectedNextDate = new Date(creationDate);
      expectedNextDate.setDate(expectedNextDate.getDate() + 7);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: creationDate,
      });

      expect(dto.dataProssimaPulizia).toBe(expectedNextDate.toISOString());
    });

    it("handles very old creation date", () => {
      const oldDate = new Date("1970-01-01T00:00:00.000Z");
      const expectedNextDate = new Date(oldDate);
      expectedNextDate.setDate(expectedNextDate.getDate() + 7);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 7,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: oldDate,
      });

      expect(dto.dataProssimaPulizia).toBe(expectedNextDate.toISOString());
    });

    it("handles very recent dates with precision", () => {
      const baseDate = new Date("2026-05-18T14:23:45.123Z");
      const expectedNextDate = new Date(baseDate);
      expectedNextDate.setDate(expectedNextDate.getDate() + 3);

      const dto = converter.toDto({
        id: "t1",
        task: "Task",
        cadenzaGiorni: 3,
        rotazioneAttiva: true,
        assegnatarioCorrente: "u1",
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        dataUltimaPulizia: null,
        dataCreazione: baseDate,
      });

      expect(dto.dataProssimaPulizia).toBe(expectedNextDate.toISOString());
    });
  });
});

describe("TurnoService - Boundary and Edge Cases", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const baseTurno = {
    id: "t1",
    task: "Pulizia",
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

  describe("Rotation wrap-around", () => {
    it("wraps around when rotating from last index", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue({
        ...baseTurno,
        ordineRotazione: ["u1", "u2", "u3"],
        indiceRotazioneCorrente: 2,
        assegnatarioCorrente: "u3",
      });
      mocks.updateTurno.mockResolvedValue(baseTurno);
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2", "u3"]);

      const service = new TurnoService();

      await service.completaTurno("c1", "t1", "u3");

      const [, updateArg] = mocks.updateTurno.mock.calls[0] as [
        string,
        { indiceRotazioneCorrente: number; assegnatarioCorrente: string },
      ];
      expect(updateArg.indiceRotazioneCorrente).toBe(0);
      expect(updateArg.assegnatarioCorrente).toBe("u1");
    });

    it("handles rotation with 2 members wrap-around", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue({
        ...baseTurno,
        ordineRotazione: ["u1", "u2"],
        indiceRotazioneCorrente: 1,
        assegnatarioCorrente: "u2",
      });
      mocks.updateTurno.mockResolvedValue(baseTurno);
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);

      const service = new TurnoService();

      await service.completaTurno("c1", "t1", "u2");

      const [, updateArg] = mocks.updateTurno.mock.calls[0] as [
        string,
        { indiceRotazioneCorrente: number },
      ];
      expect(updateArg.indiceRotazioneCorrente).toBe(0);
    });
  });

  describe("Single member scenarios", () => {
    it("handles single member rotation (stays at index 0)", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue({
        ...baseTurno,
        ordineRotazione: ["u1"],
        indiceRotazioneCorrente: 0,
        assegnatarioCorrente: "u1",
      });
      mocks.updateTurno.mockResolvedValue(baseTurno);
      mocks.getMembriCasaIds.mockResolvedValue(["u1"]);

      const service = new TurnoService();

      await service.completaTurno("c1", "t1", "u1");

      const [, updateArg] = mocks.updateTurno.mock.calls[0] as [
        string,
        { indiceRotazioneCorrente: number; assegnatarioCorrente: string },
      ];
      expect(updateArg.indiceRotazioneCorrente).toBe(0);
      expect(updateArg.assegnatarioCorrente).toBe("u1");
    });
  });

  describe("Large rotation arrays", () => {
    it("handles rotation with 50 members", async () => {
      const members = Array.from({ length: 50 }, (_, i) => `u${i + 1}`);

      mocks.findTurnoByIdOrThrow.mockResolvedValue({
        ...baseTurno,
        ordineRotazione: members,
        indiceRotazioneCorrente: 25,
        assegnatarioCorrente: "u26",
      });
      mocks.updateTurno.mockResolvedValue(baseTurno);
      mocks.getMembriCasaIds.mockResolvedValue(members);

      const service = new TurnoService();

      await service.completaTurno("c1", "t1", "u26");

      const [, updateArg] = mocks.updateTurno.mock.calls[0] as [
        string,
        { indiceRotazioneCorrente: number },
      ];
      expect(updateArg.indiceRotazioneCorrente).toBe(26);
    });

    it("adds many new members to rotation", async () => {
      mocks.findTurnoByIdOrThrow.mockResolvedValue({
        ...baseTurno,
        ordineRotazione: ["u1"],
      });
      const newMembers = Array.from({ length: 100 }, (_, i) => `u${i + 1}`);
      mocks.getMembriCasaIds.mockResolvedValue(newMembers);
      mocks.updateTurno.mockResolvedValue(baseTurno);

      const service = new TurnoService();

      await service.modificaTurno("c1", "t1", { task: "Updated" }, "u1");

      const [, updateArg] = mocks.updateTurno.mock.calls[0] as [
        string,
        { ordineRotazione: string[] },
      ];
      expect(updateArg.ordineRotazione).toHaveLength(100);
      expect(updateArg.ordineRotazione[0]).toBe("u1");
    });
  });

  describe("Cadenza edge cases in service", () => {
    it("creates turno with minimum cadenza (1 day)", async () => {
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
      mocks.createTurno.mockResolvedValue({
        ...baseTurno,
        cadenzaGiorni: 1,
      });

      const service = new TurnoService();

      await service.creaTurno(
        "c1",
        {
          task: "Daily task",
          cadenzaGiorni: 1,
          assegnatario: "u1",
          rotazioneTurno: true,
        },
        "u1",
      );

      const [dataArg] = mocks.createTurno.mock.calls[0] as [
        { cadenzaGiorni: number },
      ];
      expect(dataArg.cadenzaGiorni).toBe(1);
    });

    it("creates turno with very large cadenza (365 days)", async () => {
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
      mocks.createTurno.mockResolvedValue({
        ...baseTurno,
        cadenzaGiorni: 365,
      });

      const service = new TurnoService();

      await service.creaTurno(
        "c1",
        {
          task: "Yearly task",
          cadenzaGiorni: 365,
          assegnatario: "u1",
          rotazioneTurno: true,
        },
        "u1",
      );

      const [dataArg] = mocks.createTurno.mock.calls[0] as [
        { cadenzaGiorni: number },
      ];
      expect(dataArg.cadenzaGiorni).toBe(365);
    });
  });

  describe("No rotation scenarios", () => {
    it("creates turno without rotation (rotazioneTurno=false)", async () => {
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
      mocks.createTurno.mockResolvedValue({
        ...baseTurno,
        rotazioneAttiva: false,
      });

      const service = new TurnoService();

      await service.creaTurno(
        "c1",
        {
          task: "Single person task",
          cadenzaGiorni: 7,
          assegnatario: "u1",
          rotazioneTurno: false,
        },
        "u1",
      );

      const [dataArg] = mocks.createTurno.mock.calls[0] as [
        { ordineRotazione: string[] },
      ];
      expect(dataArg.ordineRotazione).toEqual(["u1"]);
      expect(dataArg.ordineRotazione).toHaveLength(1);
    });

    it("handles turno rotation with single member", async () => {
      mocks.getMembriCasaIds.mockResolvedValue(["u1"]);
      mocks.createTurno.mockResolvedValue({
        ...baseTurno,
        ordineRotazione: ["u1"],
      });

      const service = new TurnoService();

      await service.creaTurno(
        "c1",
        {
          task: "Single member rotation",
          cadenzaGiorni: 7,
          assegnatario: "u1",
          rotazioneTurno: true,
        },
        "u1",
      );

      const [dataArg] = mocks.createTurno.mock.calls[0] as [
        { ordineRotazione: string[] },
      ];
      expect(dataArg.ordineRotazione).toEqual(["u1"]);
    });
  });

  describe("Empty results", () => {
    it("handles getAllTurni with no results", async () => {
      mocks.findTurniByCasa.mockResolvedValue([]);

      const service = new TurnoService();

      const result = await service.getAllTurni("c1");

      expect(result).toEqual([]);
      expect(result).toHaveLength(0);
    });

    it("handles getTurniOdierni filtering with no matches", async () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      const turnoTomorrow = {
        ...baseTurno,
        dataCreazione: tomorrow,
      };

      mocks.findTurniByCasa.mockResolvedValue([turnoTomorrow]);

      const service = new TurnoService();

      const result = await service.getTurniOdierni("c1");

      expect(result).toHaveLength(0);
    });
  });

  describe("Special characters and unicode", () => {
    it("handles task with special characters", async () => {
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
      mocks.createTurno.mockResolvedValue({
        ...baseTurno,
        task: "Pulizia 🧹 & igiene ✨",
      });

      const service = new TurnoService();

      await service.creaTurno(
        "c1",
        {
          task: "Pulizia 🧹 & igiene ✨",
          cadenzaGiorni: 7,
          assegnatario: "u1",
          rotazioneTurno: true,
        },
        "u1",
      );

      const [dataArg] = mocks.createTurno.mock.calls[0] as [
        { task: string },
      ];
      expect(dataArg.task).toBe("Pulizia 🧹 & igiene ✨");
    });

    it("handles task with very long text", async () => {
      const longTask = "A".repeat(1000);
      mocks.getMembriCasaIds.mockResolvedValue(["u1", "u2"]);
      mocks.createTurno.mockResolvedValue({
        ...baseTurno,
        task: longTask,
      });

      const service = new TurnoService();

      await service.creaTurno(
        "c1",
        {
          task: longTask,
          cadenzaGiorni: 7,
          assegnatario: "u1",
          rotazioneTurno: true,
        },
        "u1",
      );

      const [dataArg] = mocks.createTurno.mock.calls[0] as [
        { task: string },
      ];
      expect(dataArg.task).toHaveLength(1000);
    });
  });
});

