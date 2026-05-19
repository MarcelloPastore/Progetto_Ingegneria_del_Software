import { FastifyInstance } from "fastify";

import { Ruolo } from "@prisma/client";
import { requireRole } from "../middleware/RoleMiddleware";

//import { AuthController } from "../controller/AuthController";
//import { authMiddleware } from "../middleware/AuthMiddleware";
import { SpesaController } from "../controller/SpesaController";
//import { CasaController } from "../controller/CasaController";
import { TurnoController } from "../controller/TurnoController";
//import { ProblemaController } from "../controller/ProblemaController";

import { SpesaService } from "../service/SpesaService";
import { TurnoService } from "../service/TurnoService";

import {CasaParams, SpesaParams, TurnoParams} from "../types/params";
import {
  AssegnaTurnoDto,
  CreaTurnoDto,
  ModificaTurnoDto,
} from "../dto/TurnoDto";


// ─── Health ───────────────────────────────────────────────────────────────────

export async function health(app: FastifyInstance) {
  app.get("/health", async () => {
    return { status: "ok" };
  });
}

// ─── Auth (no authMiddleware) ─────────────────────────────────────────────────
//
// Controller: AuthController
// Boundary:   LoginScreens, RegisterScreens
//
// POST /auth/register          → Registrazione nuovo utente (UC: Registrazione Utente)
// POST /auth/login             → Login con email+password, restituisce JWT (UC: Login)
// POST /auth/recupera-password → Invio codice di recupero via email (UC: Recupero Password)
// GET  /auth/verifica-email    → Attivazione account tramite link di verifica (UC: Registrazione)
// POST /auth/reset-password    → Reset password usando codice di recupero (UC: Recupero Password - variante)

/*export async function authRoutes(app: FastifyInstance) {
  const authController = new AuthController();

  app.post("/auth/register",
    {
      config: { rateLimit: { max: 10, timeWindow: "1 minute" } },
    },
    authController.register
  );
  app.post("/auth/login",
    {
      config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
    },
    authController.login
  );
  app.post("/auth/recupera-password", authController.recuperaPassword);
  app.get("/auth/verifica-email", authController.verificaEmail);
  app.post("/auth/refresh-token", authController.refreshToken);
  app.post("/auth/reset-password", authController.resetPassword);
}*/

// ─── Hub Casa ─────────────────────────────────────────────────────────────────
//
// Controller: CasaController
// Boundary:   HubCasaScreens
//
// POST   /case                                          → Crea una nuova casa e genera invite link (UC: Creazione Casa)
// GET    /case                                          → Lista delle case di cui l'utente fa parte (UC: Hub Casa)
// GET    /case/:idCasa                                  → Dettaglio di una singola casa
// DELETE /case/:idCasa                                  → Elimina la casa (solo HomeAdmin)
//
// GET    /case/:idCasa/inquilini                        → Lista inquilini della casa
// GET    /case/:idCasa/inquilini/:idUtente              → Dettaglio di un inquilino (ruolo, data ingresso, ecc.)
// POST   /case/:idCasa/inquilini                        → Aggiunge un inquilino tramite invite link (UC: Aggiunta Inquilino)
// DELETE /case/:idCasa/inquilini/:idUtente              → Rimuove un inquilino (solo HomeAdmin, UC: Rimozione Inquilino)
//
// PUT    /case/:idCasa/inquilini/:idUtente/ruolo        → Promuove/degrada il ruolo di un inquilino (UC: Modifica Ruolo)
//
// GET    /case/:idCasa/invite-link                      → Recupera o rigenera il link/codice di invito

/*export async function casaRoutes(app: FastifyInstance) {
  const casaController = new CasaController();
  app.addHook("onRequest", authMiddleware);

  // CRUD casa
  app.post("/case", casaController.creaCasa);
  app.get("/case", casaController.getCase);
  app.get("/case/:idCasa", casaController.getCasa);
  app.delete("/case/:idCasa", casaController.eliminaCasa);

  // Inquilini
  app.get("/case/:idCasa/inquilini", casaController.getAllInquilini);
  app.get("/case/:idCasa/inquilini/:idInquilino", casaController.getInquilino);
  app.post("/case/:idCasa/inquilini", casaController.aggiungiInquilino);
  app.delete(
    "/case/:idCasa/inquilini/:idInquilino",
    casaController.rimuoviInquilino,
  );

  // Ruoli
  app.put(
    "/case/:idCasa/inquilini/:idInquilino/ruolo",
    casaController.modificaRuolo,
  );

  // Link di invito
  app.get("/case/:idCasa/invite-link", casaController.generaLink);
}*/

// ─── Spese ────────────────────────────────────────────────────────────────────
//
// Controller: SpesaController
// Boundary:   SpeseScreens, DashboardScreen
//
// GET    /case/:idCasa/spese                            → Lista spese della casa (con filtri opzionali per periodo/stato)
// GET    /case/:idCasa/spese/:id                        → Dettaglio di una singola spesa
// POST   /case/:idCasa/spese                            → Crea una nuova spesa e calcola le quote (UC: Aggiunta Nuova Spesa)
// PUT    /case/:idCasa/spese/:id                        → Modifica una spesa esistente (solo owner spesa)
// DELETE /case/:idCasa/spese/:id                        → Elimina una spesa (solo owner spesa)
//
// GET    /case/:idCasa/spese/:id/quote                  → Ripartizione quote della spesa (UC: Aggiunta Nuova Spesa)
// POST   /case/:idCasa/spese/:id/quote/:idQuota/paga    → Registra il pagamento di una quota (UC: Pagamento Quota)
//
// POST   /case/:idCasa/spese/pareggia                   → Pareggio totale dei conti (UC: Pagamento Quota - variante)
//
// GET    /case/:idCasa/saldo                            → Saldo netto dell'utente nella casa
// GET    /case/:idCasa/credito                          → Credito totale dell'utente
// GET    /case/:idCasa/debito                           → Debito totale dell'utente
// GET    /case/:idCasa/credito/:idInquilino             → Credito verso un singolo inquilino
// GET    /case/:idCasa/debito/:idInquilino              → Debito verso un singolo inquilino

export async function speseRoutes(app: FastifyInstance) {
  const speseService = new SpesaService();
  const speseController = new SpesaController(speseService);
  //app.addHook("onRequest", authMiddleware);

  // CRUD spese
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/spese",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getAllSpese,
  );
  app.get<{ Params: SpesaParams }>(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getSpesa,
  );
  app.post(
    "/case/:idCasa/spese",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.addSpesa,
  );
  app.put(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.updateSpesa,
  );
  app.delete(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.deleteSpesa,
  );

  // Quote
  app.get(
    "/case/:idCasa/spese/:idSpesa/quote",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDivisioneSpese,
  );
  app.post(
    "/case/:idCasa/spese/:idSpesa/quote/:idQuota/paga",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.pagaQuota,
  );

  // Pareggio totale
  app.post(
    "/case/:idCasa/spese/pareggia",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.pareggiaConti,
  );

  // Saldo, Credito e Debito
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/saldo",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getSaldo,
  );
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/credito",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getCreditoTot,
  );
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/debito",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDebitoTot,
  );
  app.get(
    "/case/:idCasa/credito/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getCreditoVersoUtente,
  );
  app.get(
    "/case/:idCasa/debito/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDebitoVersoUtente,
  );
}

// ─── Turni ────────────────────────────────────────────────────────────────────
//
// Controller: TurnoController
// Boundary:   TurniScreens, DashboardScreen
//
// GET    /case/:idCasa/turni                            → Lista turni della casa
// GET    /case/:idCasa/turni/turni_odierni              → Solo i turni previsti per oggi (per Dashboard)
// POST   /case/:idCasa/turni                            → Crea un nuovo turno (UC: Creazione Turno con Rotazione Automatica)
// GET    /case/:idCasa/turni/:idTurno                   → Dettaglio di un singolo turno
// PUT    /case/:idCasa/turni/:idTurno                   → Modifica un turno esistente (solo HomeAdmin)
// DELETE /case/:idCasa/turni/:idTurno                   → Elimina un turno (solo HomeAdmin)
// PUT    /case/:idCasa/turni/:idTurno/autoassegna       → Auto-assegnazione del turno a sé stessi (Inquilino)
// PUT    /case/:idCasa/turni/:idTurno/assegna           → Assegnazione del turno ad Inquilino (solo HomeAdmin)
// PATCH  /case/:idCasa/turni/:idTurno/rotazione         → Attiva/disattiva la rotazione automatica (solo HomeAdmin)
// POST   /case/:idCasa/turni/:idTurno/completa          → Marca il turno come completato e aggiorna la prossima scadenza

export async function turniRoutes(app: FastifyInstance) {
  const turniService = new TurnoService();
  const turnoController = new TurnoController(turniService);
  //app.addHook("onRequest", authMiddleware);

  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/turni",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getAllTurni,
  );
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/turni/oggi",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getTurniOdierni,
  );
  app.post<{ Params: CasaParams; Body: CreaTurnoDto }>(
    "/case/:idCasa/turni",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.creaTurno,
  );
  app.get<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getTurno,
  );
  app.put<{ Params: TurnoParams; Body: ModificaTurnoDto }>(
    "/case/:idCasa/turni/:idTurno",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.modificaTurno,
  );
  app.delete<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.eliminaTurno,
  );
  app.put<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno/autoassegna",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.autoassegnaTurno,
  );
  app.put<{ Params: TurnoParams; Body: AssegnaTurnoDto }>(
    "/case/:idCasa/turni/:idTurno/assegna",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    turnoController.assegnaTurno,
  );
  app.patch<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno/rotazione",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    turnoController.toggleRotazioneTurni,
  );
  app.post<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno/completa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.completaTurno,
  );
}

// ─── Problemi ─────────────────────────────────────────────────────────────────
//
// Controller: ProblemaController
// Boundary:   ProblemiScreens, DashboardScreen
//
// GET    /case/:idCasa/problemi                                         → Lista problemi della casa (aperti e risolti)
// GET    /case/:idCasa/problemi/non-risolti                             → Solo i problemi non risolti (per Dashboard)
// POST   /case/:idCasa/problemi                                         → Segnala un nuovo problema (UC: Segnalazione Problema)
// DELETE /case/:idCasa/problemi/:idProblema                             → Elimina un problema (solo HomeAdmin)
//
// PUT    /case/:idCasa/problemi/:idProblema/assegna                     → Assegna/de-assegna il problema a sé stessi (UC: Assegnazione e Risoluzione)
// PATCH  /case/:idCasa/problemi/:idProblema/stato                       → Aggiorna lo stato (Segnalato → Assegnato → Risolto)
// PATCH  /case/:idCasa/problemi/:idProblema/priorita                    → Aggiorna la priorità (Urgente / Media / Bassa)

/*export async function problemiRoutes(app: FastifyInstance) {
  const problemaController = new ProblemaController();
  app.addHook("onRequest", authMiddleware);

  // CRUD problemi
  app.get("/case/:idCasa/problemi", problemaController.getAllProblemi);
  app.get(
    "/case/:idCasa/problemi/non-risolti",
    problemaController.getProblemiNonRisolti,
  );
  app.post("/case/:idCasa/problemi", problemaController.segnalaProblema);

  app.delete(
    "/case/:idCasa/problemi/:idProblema",
    problemaController.eliminaProblema,
  );

  // Assegnazione e aggiornamento
  app.put(
    "/case/:idCasa/problemi/:idProblema/assegna",
    problemaController.assegnaProblema,
  );
  app.patch(
    "/case/:idCasa/problemi/:idProblema/stato",
    problemaController.aggiornaStato,
  );
  app.patch(
    "/case/:idCasa/problemi/:idProblema/priorita",
    problemaController.aggiornaPriorita,
  );
}*/
