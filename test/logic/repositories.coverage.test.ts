import { describe, it, expect, vi, beforeEach } from "vitest";
import { Priorita, Ruolo, Stato } from "@prisma/client";

const mocks = vi.hoisted(() => ({
  prisma: {
    $transaction: vi.fn(),
    casa: {
      create: vi.fn(),
      delete: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    documento: { deleteMany: vi.fn() },
    membroCasa: {
      create: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
      findFirst: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
    },
    problema: {
      create: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
    },
    quotaSpesa: {
      aggregate: vi.fn(),
      createMany: vi.fn(),
      deleteMany: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
      updateMany: vi.fn(),
    },
    scadenza: {
      create: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
    },
    spesa: {
      create: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
    },
    storico: {
      create: vi.fn(),
      deleteMany: vi.fn(),
    },
    turno: {
      create: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
      findFirstOrThrow: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
    },
  },
}));

vi.mock("../../src/config/db", () => ({
  prisma: mocks.prisma,
}));

import { CasaRepository } from "../../src/repository/CasaRepository";
import { ProblemaRepository } from "../../src/repository/ProblemaRepository";
import { ScadenzaRepository } from "../../src/repository/ScadenzaRepository";
import { SpesaRepository } from "../../src/repository/SpesaRepository";
import { TurnoRepository } from "../../src/repository/TurnoRepository";

describe("Repository query builders", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.prisma.$transaction.mockImplementation(async (callback) =>
      callback(mocks.prisma),
    );
  });

  it("CasaRepository builds house and membership queries", async () => {
    const repository = new CasaRepository();
    mocks.prisma.casa.create.mockResolvedValue({ id: "c1" });
    mocks.prisma.casa.findMany.mockResolvedValue([{ id: "c1" }]);
    mocks.prisma.casa.findFirstOrThrow.mockResolvedValue({ id: "c1" });
    mocks.prisma.casa.update.mockResolvedValue({ id: "c1" });
    mocks.prisma.casa.findUnique.mockResolvedValue({ creator: "u1" });
    mocks.prisma.membroCasa.findMany.mockResolvedValue([
      { idUtente: "u1" },
      { idUtente: "u2" },
    ]);
    mocks.prisma.membroCasa.findFirst.mockResolvedValue({ id: "m1" });
    mocks.prisma.membroCasa.findFirstOrThrow.mockResolvedValue({ id: "m1" });
    mocks.prisma.membroCasa.create.mockResolvedValue({ id: "m2" });
    mocks.prisma.membroCasa.update.mockResolvedValue({ id: "m1" });

    await repository.createCasa({
      nome: "Casa",
      indirizzo: "Via Roma",
      citta: "Milano",
      tipoCasa: "Appartamento",
      creator: "u1",
      inviteLink: "invite",
    });
    expect(mocks.prisma.casa.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          creatorRel: { connect: { id: "u1" } },
          membri: {
            create: {
              ruolo: Ruolo.HomeAdmin,
              utenteRel: { connect: { id: "u1" } },
            },
          },
        }),
      }),
    );

    await repository.findCaseByUser("u1");
    expect(mocks.prisma.casa.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { membri: { some: { idUtente: "u1" } } },
      }),
    );

    await repository.findCasaByIdOrThrow("c1");
    await repository.findCasaByIdAndInviteLinkOrThrow("c1", "invite");
    await repository.updateCasa("c1", { nome: "Casa nuova" });
    expect(mocks.prisma.casa.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "c1" },
        data: { nome: "Casa nuova" },
      }),
    );

    await expect(repository.getMembriCasaIds("c1")).resolves.toEqual([
      "u1",
      "u2",
    ]);
    await expect(repository.getCasaCreator("c1")).resolves.toBe("u1");
    await repository.findMembroCasaByCasaAndUtente("c1", "u1");
    await repository.findMembroCasaByCasaAndUtenteOrThrow("c1", "u1");
    await repository.addMembroCasa("c1", "u3", Ruolo.HomeAdmin);
    expect(mocks.prisma.membroCasa.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          ruolo: Ruolo.HomeAdmin,
          casaRel: { connect: { id: "c1" } },
          utenteRel: { connect: { id: "u3" } },
        }),
      }),
    );

    await repository.updateMembroCasaRole("c1", "u1", Ruolo.Inquilino);
    expect(mocks.prisma.membroCasa.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "m1" },
        data: { ruolo: Ruolo.Inquilino },
      }),
    );

    await repository.removeMembroCasa("c1", "u1");
    expect(mocks.prisma.membroCasa.delete).toHaveBeenCalledWith({
      where: { id: "m1" },
    });
  });

  it("CasaRepository cascades deletes in a transaction", async () => {
    const repository = new CasaRepository();

    await repository.deleteCasa("c1");

    expect(mocks.prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(mocks.prisma.quotaSpesa.deleteMany).toHaveBeenCalledWith({
      where: { idCasa: "c1" },
    });
    expect(mocks.prisma.casa.delete).toHaveBeenCalledWith({
      where: { id: "c1" },
    });
  });

  it("ProblemaRepository builds problem queries", async () => {
    const repository = new ProblemaRepository();
    mocks.prisma.problema.create.mockResolvedValue({ id: "p1" });
    mocks.prisma.problema.update.mockResolvedValue({ id: "p1" });
    mocks.prisma.problema.findMany.mockResolvedValue([{ id: "p1" }]);
    mocks.prisma.problema.findFirstOrThrow.mockResolvedValue({ id: "p1" });
    mocks.prisma.problema.delete.mockResolvedValue({ id: "p1" });

    await repository.createProblema({
      idCasa: "c1",
      nome: "Perdita",
      descrizione: "Bagno",
      segnalataDa: "u1",
      priorita: Priorita.Urgente,
    });
    expect(mocks.prisma.problema.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ idCasa: "c1", priorita: "Urgente" }),
      }),
    );

    await repository.updateProblema("p1", {
      stato: Stato.Risolto,
      dataRisoluzione: new Date("2026-06-01T00:00:00.000Z"),
    });
    expect(mocks.prisma.problema.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "p1" },
        data: expect.objectContaining({ stato: Stato.Risolto }),
      }),
    );

    await repository.findProblemiByCasa("c1");
    await repository.findProblemiNonRisolti("c1");
    expect(mocks.prisma.problema.findMany).toHaveBeenLastCalledWith(
      expect.objectContaining({
        where: { idCasa: "c1", stato: { not: Stato.Risolto } },
      }),
    );

    await repository.findProblemaByIdOrThrow("c1", "p1");
    await repository.deleteProblema("c1", "p1");
    expect(mocks.prisma.problema.delete).toHaveBeenCalledWith({
      where: { id: "p1", idCasa: "c1" },
    });
  });

  it("ScadenzaRepository builds deadline queries with optional update fields", async () => {
    const repository = new ScadenzaRepository();
    const date = new Date("2026-06-30T00:00:00.000Z");
    mocks.prisma.scadenza.create.mockResolvedValue({ id: "s1" });
    mocks.prisma.scadenza.update.mockResolvedValue({ id: "s1" });
    mocks.prisma.scadenza.findMany.mockResolvedValue([{ id: "s1" }]);
    mocks.prisma.scadenza.findFirstOrThrow.mockResolvedValue({ id: "s1" });
    mocks.prisma.scadenza.delete.mockResolvedValue({ id: "s1" });

    await repository.createScadenza({
      idCasa: "c1",
      nome: "Affitto",
      descrizione: "",
      dataScadenza: date,
      isRicorrente: true,
      cadenzaGiorni: null,
    });
    expect(mocks.prisma.scadenza.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          cadenzaGiorni: undefined,
          dataScadenza: date,
        }),
      }),
    );

    await repository.updateScadenza("s1", {
      descrizione: "Nuova",
      isRicorrente: false,
      cadenzaGiorni: null,
    });
    expect(mocks.prisma.scadenza.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "s1" },
        data: {
          descrizione: "Nuova",
          isRicorrente: false,
          cadenzaGiorni: undefined,
        },
      }),
    );

    await repository.findScadenzeByCasa("c1");
    expect(mocks.prisma.scadenza.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { idCasa: "c1" } }),
    );

    await repository.findScadenzaByIdOrThrow("c1", "s1");
    await repository.deleteScadenza("c1", "s1");
    expect(mocks.prisma.scadenza.delete).toHaveBeenCalledWith({
      where: { id: "s1", idCasa: "c1" },
    });
  });

  it("SpesaRepository builds expense queries and transactions", async () => {
    const repository = new SpesaRepository();
    const date = new Date("2026-06-30T00:00:00.000Z");
    mocks.prisma.spesa.create.mockResolvedValue({ id: "sp1" });
    mocks.prisma.spesa.update.mockResolvedValue({ id: "sp1" });
    mocks.prisma.spesa.findFirstOrThrow.mockResolvedValue({ id: "sp1" });
    mocks.prisma.spesa.findMany.mockResolvedValue([{ id: "sp1" }]);
    mocks.prisma.quotaSpesa.findFirstOrThrow.mockResolvedValue({ id: "q1" });
    mocks.prisma.quotaSpesa.findMany.mockResolvedValue([{ id: "q1" }]);
    mocks.prisma.quotaSpesa.update.mockResolvedValue({ id: "q1" });
    mocks.prisma.quotaSpesa.updateMany.mockResolvedValue({ count: 2 });
    mocks.prisma.quotaSpesa.aggregate.mockResolvedValue({ _sum: { quota: 15 } });

    await repository.createSpesa({
      idCasa: "c1",
      descrizione: "Spesa",
      importo: 30,
      owner: "u1",
      anticipataDa: "u2",
      partecipanti: ["u1", "u2"],
      scadenza: {
        nome: "Spesa",
        descrizione: "",
        dataScadenza: date,
        isRicorrente: false,
        cadenzaGiorni: null,
      },
      quote: [
        { idUtente: "u1", quota: 15, dataPagamento: date },
        { idUtente: "u2", quota: 15 },
      ],
    });
    expect(mocks.prisma.spesa.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          anticipataDaRel: { connect: { id: "u2" } },
          partecipantiRel: { connect: [{ id: "u1" }, { id: "u2" }] },
        }),
      }),
    );

    await repository.updateSpesa(
      "c1",
      "sp1",
      {
        descrizione: "Spesa aggiornata",
        importo: 40,
        anticipataDa: null,
        partecipanti: ["u2"],
      },
      [{ idUtente: "u2", quota: 40 }],
      {
        nome: "Spesa aggiornata",
        descrizione: "",
        dataScadenza: date,
        isRicorrente: true,
        cadenzaGiorni: null,
      },
    );
    expect(mocks.prisma.spesa.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "sp1" },
        data: expect.objectContaining({
          anticipataDaRel: { disconnect: true },
          partecipantiRel: { set: [{ id: "u2" }] },
        }),
      }),
    );
    expect(mocks.prisma.quotaSpesa.createMany).toHaveBeenCalledWith({
      data: [{ idCasa: "c1", idSpesa: "sp1", idUtente: "u2", quota: 40 }],
    });

    await repository.deleteSpesa("c1", "sp1", "s1");
    expect(mocks.prisma.scadenza.delete).toHaveBeenCalledWith({
      where: { id: "s1" },
    });

    await repository.findSpeseByCasa("c1");
    await repository.findSpesaByIdOrThrow("c1", "sp1");
    await repository.findQuoteByIdOrThrow("c1", "sp1", "q1");
    await repository.findQuoteBySpesa("c1", "sp1");
    await repository.markQuotaPagata("q1");
    await expect(
      repository.saldaQuoteVersoCreditori("c1", "u1", ["u2"]),
    ).resolves.toBe(2);
    await expect(repository.sumDebito("c1", "u1")).resolves.toBe(15);
    await expect(repository.sumCredito("c1", "u1")).resolves.toBe(15);
    await expect(
      repository.sumCreditoVersoUtente("c1", "u1", "u2"),
    ).resolves.toBe(15);
    await expect(
      repository.sumDebitoVersoUtente("c1", "u1", "u2"),
    ).resolves.toBe(15);
  });

  it("TurnoRepository builds shift queries", async () => {
    const repository = new TurnoRepository();
    mocks.prisma.turno.create.mockResolvedValue({ id: "t1" });
    mocks.prisma.turno.update.mockResolvedValue({ id: "t1" });
    mocks.prisma.turno.findMany.mockResolvedValue([{ id: "t1" }]);
    mocks.prisma.turno.findFirstOrThrow.mockResolvedValue({ id: "t1" });
    mocks.prisma.turno.delete.mockResolvedValue({ id: "t1" });

    await repository.createTurno({
      idCasa: "c1",
      task: "Pulizia",
      cadenzaGiorni: 7,
      rotazioneAttiva: true,
      assegnatarioCorrente: "u1",
      ordineRotazione: ["u1", "u2"],
      indiceRotazioneCorrente: 0,
      idCreatore: "u1",
    });
    expect(mocks.prisma.turno.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ idCasa: "c1", task: "Pulizia" }),
      }),
    );

    await repository.updateTurno("t1", { task: "Bagno" });
    expect(mocks.prisma.turno.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: "t1" },
        data: { task: "Bagno" },
      }),
    );

    await repository.findTurniByCasa("c1");
    await repository.findTurnoByIdOrThrow("c1", "t1");
    await repository.deleteTurno("c1", "t1");
    expect(mocks.prisma.turno.delete).toHaveBeenCalledWith({
      where: { id: "t1", idCasa: "c1" },
    });
  });
});
