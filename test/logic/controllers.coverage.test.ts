import { describe, it, expect, vi, beforeEach } from "vitest";
import { Ruolo } from "@prisma/client";

vi.mock("../../src/config/db", () => ({
  prisma: {},
}));

import { AccountController } from "../../src/controller/AccountController";
import { CasaController } from "../../src/controller/CasaController";
import { ProblemaController } from "../../src/controller/ProblemaController";
import { ScadenzaController } from "../../src/controller/ScadenzaController";
import { SpesaController } from "../../src/controller/SpesaController";
import { TurnoController } from "../../src/controller/TurnoController";

function makeReply() {
  const reply = {
    code: vi.fn(),
    status: vi.fn(),
    send: vi.fn(),
  };
  reply.code.mockReturnValue(reply);
  reply.status.mockReturnValue(reply);
  reply.send.mockReturnValue(reply);
  return reply as any;
}

function makeRequest(overrides: Record<string, unknown> = {}) {
  return {
    params: {
      idCasa: "c1",
      idInquilino: "u2",
      idProblema: "p1",
      idQuota: "q1",
      idScadenza: "s1",
      idSpesa: "sp1",
      idTurno: "t1",
    },
    body: {},
    query: {},
    user: { idUtente: "u1", ruoloCasa: Ruolo.HomeAdmin },
    server: {
      jwt: { sign: vi.fn(() => "signed-token") },
    },
    ...overrides,
  } as any;
}

async function expectControllerResult(
  handler: (request: any, reply: any) => Promise<unknown>,
  request: any,
  expectedStatus: number,
) {
  const reply = makeReply();
  await handler(request, reply);
  expect(reply.status).toHaveBeenCalledWith(expectedStatus);
  return reply;
}

describe("Controller success paths", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("AccountController delegates account operations and sends responses", async () => {
    const service = {
      getProfilo: vi.fn().mockResolvedValue({ username: "mario" }),
      modificaUsername: vi.fn().mockResolvedValue({ username: "luigi" }),
      modificaEmail: vi.fn().mockResolvedValue({ message: "ok" }),
      eliminaAccount: vi.fn().mockResolvedValue({ message: "deleted" }),
    };
    const controller = new AccountController(service as any);

    await expectControllerResult(
      controller.getProfilo,
      makeRequest(),
      200,
    );
    expect(service.getProfilo).toHaveBeenCalledWith("u1");

    const usernameReply = await expectControllerResult(
      controller.modificaUsername,
      makeRequest({ body: { username: "luigi" } }),
      200,
    );
    expect(service.modificaUsername).toHaveBeenCalledWith("u1", {
      username: "luigi",
    });
    expect(usernameReply.send).toHaveBeenCalledWith({
      message: "Username modificato con successo.",
      profilo: { username: "luigi" },
    });

    await expectControllerResult(
      controller.modificaEmail,
      makeRequest({ body: { email: "luigi@example.com" } }),
      200,
    );
    expect(service.modificaEmail).toHaveBeenCalledWith("u1", {
      email: "luigi@example.com",
    });

    await expectControllerResult(
      controller.eliminaAccount,
      makeRequest(),
      200,
    );
    expect(service.eliminaAccount).toHaveBeenCalledWith("u1");
  });

  it("CasaController delegates house and membership operations", async () => {
    const service = {
      creaCasa: vi.fn().mockResolvedValue({ id: "c1" }),
      getCase: vi.fn().mockResolvedValue([{ id: "c1" }]),
      getCasa: vi.fn().mockResolvedValue({ id: "c1" }),
      modificaCasa: vi.fn().mockResolvedValue({ id: "c1" }),
      eliminaCasa: vi.fn().mockResolvedValue(undefined),
      getAllInquilini: vi.fn().mockResolvedValue([{ id: "m1" }]),
      getInquilino: vi.fn().mockResolvedValue({ id: "m1" }),
      aggiungiInquilino: vi.fn().mockResolvedValue({ id: "m2" }),
      rimuoviInquilino: vi.fn().mockResolvedValue(undefined),
      modificaRuolo: vi.fn().mockResolvedValue({ ruolo: Ruolo.HomeAdmin }),
      generaLink: vi.fn().mockResolvedValue({ inviteLink: "invite" }),
      selectCasa: vi.fn().mockResolvedValue({
        idCasa: "c1",
        ruoloCasa: Ruolo.HomeAdmin,
      }),
    };
    const controller = new CasaController(service as any);

    await expectControllerResult(
      controller.creaCasa,
      makeRequest({ body: { nome: "Casa" } }),
      201,
    );
    expect(service.creaCasa).toHaveBeenCalledWith({ nome: "Casa" }, "u1");

    await expectControllerResult(controller.getCase, makeRequest(), 200);
    expect(service.getCase).toHaveBeenCalledWith("u1");

    await expectControllerResult(controller.getCasa, makeRequest(), 200);
    expect(service.getCasa).toHaveBeenCalledWith("c1", "u1");

    await expectControllerResult(
      controller.modificaCasa,
      makeRequest({ body: { nome: "Nuova Casa" } }),
      204,
    );
    expect(service.modificaCasa).toHaveBeenCalledWith(
      "c1",
      "u1",
      { nome: "Nuova Casa" },
    );

    await expectControllerResult(controller.eliminaCasa, makeRequest(), 204);
    expect(service.eliminaCasa).toHaveBeenCalledWith("c1", "u1");

    await expectControllerResult(controller.getAllInquilini, makeRequest(), 200);
    expect(service.getAllInquilini).toHaveBeenCalledWith("c1", "u1");

    await expectControllerResult(controller.getInquilino, makeRequest(), 200);
    expect(service.getInquilino).toHaveBeenCalledWith("c1", "u2", "u1");

    await expectControllerResult(
      controller.aggiungiInquilino,
      makeRequest({ body: { inviteLink: "invite" } }),
      201,
    );
    expect(service.aggiungiInquilino).toHaveBeenCalledWith(
      "c1",
      { inviteLink: "invite" },
      "u1",
    );

    await expectControllerResult(controller.rimuoviInquilino, makeRequest(), 204);
    expect(service.rimuoviInquilino).toHaveBeenCalledWith("c1", "u2", "u1");

    await expectControllerResult(
      controller.modificaRuoloInquilino,
      makeRequest({ body: { ruolo: Ruolo.HomeAdmin } }),
      200,
    );
    expect(service.modificaRuolo).toHaveBeenCalledWith(
      "c1",
      "u2",
      { ruolo: Ruolo.HomeAdmin },
      "u1",
    );

    await expectControllerResult(
      controller.generaLink,
      makeRequest({ query: { rigenera: "1" } }),
      200,
    );
    expect(service.generaLink).toHaveBeenCalledWith("c1", "u1", true);

    const selectReply = await expectControllerResult(
      controller.selectCasa,
      makeRequest(),
      200,
    );
    expect(service.selectCasa).toHaveBeenCalledWith("c1", "u1");
    expect(selectReply.send).toHaveBeenCalledWith({ token: "signed-token" });
  });

  it("ProblemaController delegates problem operations", async () => {
    const service = {
      getAllProblemi: vi.fn().mockResolvedValue([]),
      getProblemiIrrisolti: vi.fn().mockResolvedValue([]),
      getProblema: vi.fn().mockResolvedValue({ id: "p1" }),
      segnalaProblema: vi.fn().mockResolvedValue({ id: "p1" }),
      eliminaProblema: vi.fn().mockResolvedValue(undefined),
      autoassegnaProblema: vi.fn().mockResolvedValue({ id: "p1" }),
      assegnaProblema: vi.fn().mockResolvedValue({ id: "p1" }),
      aggiornaStato: vi.fn().mockResolvedValue({ stato: "Risolto" }),
      aggiornaPriorita: vi.fn().mockResolvedValue({ priorita: "Urgente" }),
    };
    const controller = new ProblemaController(service as any);

    await expectControllerResult(controller.getAllProblemi, makeRequest(), 200);
    expect(service.getAllProblemi).toHaveBeenCalledWith("c1");

    await expectControllerResult(
      controller.getProblemiNonRisolti,
      makeRequest(),
      200,
    );
    expect(service.getProblemiIrrisolti).toHaveBeenCalledWith("c1");

    await expectControllerResult(controller.getProblema, makeRequest(), 200);
    expect(service.getProblema).toHaveBeenCalledWith("c1", "p1");

    await expectControllerResult(
      controller.segnalaProblema,
      makeRequest({
        body: { nome: "Lavatrice", descrizione: "Perde acqua" },
      }),
      201,
    );
    expect(service.segnalaProblema).toHaveBeenCalledWith(
      "c1",
      { nome: "Lavatrice", descrizione: "Perde acqua" },
      "u1",
    );

    await expectControllerResult(controller.eliminaProblema, makeRequest(), 204);
    expect(service.eliminaProblema).toHaveBeenCalledWith("c1", "p1", "u1");

    await expectControllerResult(
      controller.autoassegnaProblema,
      makeRequest(),
      200,
    );
    expect(service.autoassegnaProblema).toHaveBeenCalledWith("c1", "p1", "u1");

    await expectControllerResult(
      controller.assegnaProblema,
      makeRequest({ body: { idUtente: "u2" } }),
      200,
    );
    expect(service.assegnaProblema).toHaveBeenCalledWith(
      "c1",
      "p1",
      { idUtente: "u2" },
      "u1",
    );

    await expectControllerResult(
      controller.aggiornaStato,
      makeRequest({ body: { stato: "Risolto" } }),
      200,
    );
    expect(service.aggiornaStato).toHaveBeenCalledWith(
      "c1",
      "p1",
      { stato: "Risolto" },
      "u1",
    );

    await expectControllerResult(
      controller.aggiornaPriorita,
      makeRequest({ body: { priorita: "Urgente" } }),
      200,
    );
    expect(service.aggiornaPriorita).toHaveBeenCalledWith("c1", "p1", {
      priorita: "Urgente",
    });
  });

  it("ScadenzaController delegates deadline operations", async () => {
    const service = {
      getAllScadenze: vi.fn().mockResolvedValue([]),
      getScadenza: vi.fn().mockResolvedValue({ id: "s1" }),
      creaScadenza: vi.fn().mockResolvedValue({ id: "s1" }),
      modificaScadenza: vi.fn().mockResolvedValue({ id: "s1" }),
      eliminaScadenza: vi.fn().mockResolvedValue(undefined),
      aggiornaRicorrenza: vi.fn().mockResolvedValue({ id: "s1" }),
    };
    const controller = new ScadenzaController(service as any);

    await expectControllerResult(controller.getAllScadenze, makeRequest(), 200);
    expect(service.getAllScadenze).toHaveBeenCalledWith("c1");

    await expectControllerResult(controller.getScadenza, makeRequest(), 200);
    expect(service.getScadenza).toHaveBeenCalledWith("c1", "s1");

    await expectControllerResult(
      controller.creaScadenza,
      makeRequest({
        body: { nome: "Affitto", dataScadenza: "2026-06-30" },
      }),
      201,
    );
    expect(service.creaScadenza).toHaveBeenCalledWith(
      "c1",
      expect.objectContaining({ nome: "Affitto" }),
      "u1",
    );

    await expectControllerResult(
      controller.modificaScadenza,
      makeRequest({ body: { descrizione: "Aggiornata" } }),
      200,
    );
    expect(service.modificaScadenza).toHaveBeenCalledWith(
      "c1",
      "s1",
      { descrizione: "Aggiornata" },
      "u1",
      Ruolo.HomeAdmin,
    );

    await expectControllerResult(controller.eliminaScadenza, makeRequest(), 204);
    expect(service.eliminaScadenza).toHaveBeenCalledWith("c1", "s1", "u1");

    await expectControllerResult(
      controller.aggiornaRicorrenza,
      makeRequest({ body: { isRicorrente: true, cadenzaGiorni: 30 } }),
      200,
    );
    expect(service.aggiornaRicorrenza).toHaveBeenCalledWith(
      "c1",
      "s1",
      { isRicorrente: true, cadenzaGiorni: 30 },
    );
  });

  it("TurnoController delegates shift operations", async () => {
    const service = {
      getAllTurni: vi.fn().mockResolvedValue([]),
      getTurniOdierni: vi.fn().mockResolvedValue([]),
      getGiorniDallUltimaPulizia: vi.fn().mockResolvedValue([]),
      creaTurno: vi.fn().mockResolvedValue({ id: "t1" }),
      getTurno: vi.fn().mockResolvedValue({ id: "t1" }),
      modificaTurno: vi.fn().mockResolvedValue({ id: "t1" }),
      eliminaTurno: vi.fn().mockResolvedValue(undefined),
      autoassegnaTurno: vi.fn().mockResolvedValue({ id: "t1" }),
      assegnaTurno: vi.fn().mockResolvedValue({ id: "t1" }),
      toggleRotazioneTurni: vi.fn().mockResolvedValue({ id: "t1" }),
      completaTurno: vi.fn().mockResolvedValue({ id: "t1" }),
    };
    const controller = new TurnoController(service as any);

    await expectControllerResult(controller.getAllTurni, makeRequest(), 200);
    expect(service.getAllTurni).toHaveBeenCalledWith("c1");

    await expectControllerResult(controller.getTurniOdierni, makeRequest(), 200);
    expect(service.getTurniOdierni).toHaveBeenCalledWith("c1");

    await expectControllerResult(
      controller.getGiorniDallUltimaPulizia,
      makeRequest(),
      200,
    );
    expect(service.getGiorniDallUltimaPulizia).toHaveBeenCalledWith("c1");

    await expectControllerResult(
      controller.creaTurno,
      makeRequest({
        body: {
          task: "Pulizia",
          dataTurno: "2026-06-30T00:00:00.000Z",
          cadenzaGiorni: 7,
          assegnatario: "u1",
        },
      }),
      201,
    );
    expect(service.creaTurno).toHaveBeenCalledWith(
      "c1",
      expect.objectContaining({ task: "Pulizia" }),
      "u1",
    );

    await expectControllerResult(controller.getTurno, makeRequest(), 200);
    expect(service.getTurno).toHaveBeenCalledWith("c1", "t1");

    await expectControllerResult(
      controller.modificaTurno,
      makeRequest({ body: { task: "Bagno" } }),
      200,
    );
    expect(service.modificaTurno).toHaveBeenCalledWith(
      "c1",
      "t1",
      { task: "Bagno" },
      "u1",
    );

    await expectControllerResult(controller.eliminaTurno, makeRequest(), 204);
    expect(service.eliminaTurno).toHaveBeenCalledWith("c1", "t1", "u1");

    await expectControllerResult(controller.autoassegnaTurno, makeRequest(), 200);
    expect(service.autoassegnaTurno).toHaveBeenCalledWith("c1", "t1", "u1");

    await expectControllerResult(
      controller.assegnaTurno,
      makeRequest({ body: { idUtente: "u2" } }),
      200,
    );
    expect(service.assegnaTurno).toHaveBeenCalledWith("c1", "t1", {
      idUtente: "u2",
    });

    await expectControllerResult(
      controller.toggleRotazioneTurni,
      makeRequest(),
      200,
    );
    expect(service.toggleRotazioneTurni).toHaveBeenCalledWith("c1", "t1");

    await expectControllerResult(controller.completaTurno, makeRequest(), 200);
    expect(service.completaTurno).toHaveBeenCalledWith("c1", "t1", "u1");
  });

  it("SpesaController delegates expense operations", async () => {
    const service = {
      getAllSpese: vi.fn().mockResolvedValue([]),
      getSpesa: vi.fn().mockResolvedValue({ id: "sp1" }),
      getSaldo: vi.fn().mockResolvedValue({ saldo: 10 }),
      getCredito: vi.fn().mockResolvedValue({ credito: 10 }),
      getDebito: vi.fn().mockResolvedValue({ debito: 5 }),
      addSpesa: vi.fn().mockResolvedValue({ id: "sp1" }),
      updateSpesa: vi.fn().mockResolvedValue({ id: "sp1" }),
      deleteSpesa: vi.fn().mockResolvedValue(undefined),
      getDivisioneSpese: vi.fn().mockResolvedValue([]),
      getQuota: vi.fn().mockResolvedValue({ id: "q1" }),
      pagaQuota: vi.fn().mockResolvedValue({ id: "q1" }),
      pareggiaConti: vi.fn().mockResolvedValue(undefined),
      getCreditoVersoUtente: vi.fn().mockResolvedValue({ credito: 4 }),
      getDebitoVersoUtente: vi.fn().mockResolvedValue({ debito: 3 }),
    };
    const controller = new SpesaController(service as any);

    await expectControllerResult(controller.getAllSpese, makeRequest(), 200);
    expect(service.getAllSpese).toHaveBeenCalledWith("c1");

    await expectControllerResult(controller.getSpesa, makeRequest(), 200);
    expect(service.getSpesa).toHaveBeenCalledWith("c1", "sp1");

    await expectControllerResult(controller.getSaldo, makeRequest(), 200);
    expect(service.getSaldo).toHaveBeenCalledWith("c1", "u1");

    await expectControllerResult(controller.getCreditoTot, makeRequest(), 200);
    expect(service.getCredito).toHaveBeenCalledWith("c1", "u1");

    await expectControllerResult(controller.getDebitoTot, makeRequest(), 200);
    expect(service.getDebito).toHaveBeenCalledWith("c1", "u1");

    await expectControllerResult(
      controller.addSpesa,
      makeRequest({
        body: {
          descrizione: "Spesa",
          importo: 20,
          partecipanti: ["u1", "u2"],
        },
      }),
      201,
    );
    expect(service.addSpesa).toHaveBeenCalledWith(
      "c1",
      expect.objectContaining({ descrizione: "Spesa" }),
      "u1",
    );

    await expectControllerResult(
      controller.updateSpesa,
      makeRequest({ body: { descrizione: "Nuova spesa" } }),
      200,
    );
    expect(service.updateSpesa).toHaveBeenCalledWith(
      "c1",
      "sp1",
      { descrizione: "Nuova spesa" },
      "u1",
    );

    await expectControllerResult(controller.deleteSpesa, makeRequest(), 204);
    expect(service.deleteSpesa).toHaveBeenCalledWith("c1", "sp1", "u1");

    await expectControllerResult(controller.getDivisioneSpese, makeRequest(), 200);
    expect(service.getDivisioneSpese).toHaveBeenCalledWith("c1", "sp1");

    await expectControllerResult(controller.getQuota, makeRequest(), 200);
    expect(service.getQuota).toHaveBeenCalledWith("c1", "sp1", "q1", "u1");

    await expectControllerResult(controller.pagaQuota, makeRequest(), 200);
    expect(service.pagaQuota).toHaveBeenCalledWith("c1", "sp1", "q1", "u1");

    await expectControllerResult(
      controller.pareggiaConti,
      makeRequest({ body: { idUtentiCreditori: ["u2"] } }),
      204,
    );
    expect(service.pareggiaConti).toHaveBeenCalledWith(
      "c1",
      "u1",
      { idUtentiCreditori: ["u2"] },
    );

    await expectControllerResult(
      controller.getCreditoVersoUtente,
      makeRequest(),
      200,
    );
    expect(service.getCreditoVersoUtente).toHaveBeenCalledWith("c1", "u2", "u1");

    await expectControllerResult(
      controller.getDebitoVersoUtente,
      makeRequest(),
      200,
    );
    expect(service.getDebitoVersoUtente).toHaveBeenCalledWith("c1", "u2", "u1");
  });
});
