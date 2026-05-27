import { FastifyInstance, FastifyRequest } from "fastify";
import { Ruolo } from "@prisma/client";

import { requireRole } from "../middleware/RoleMiddleware";
import { authMiddleware } from "../middleware/AuthMiddleware";

import { AuthController } from "../controller/AuthController";
import { CasaController } from "../controller/CasaController";
import { SpesaController } from "../controller/SpesaController";
import { ProblemaController } from "../controller/ProblemaController";
import { TurnoController } from "../controller/TurnoController";

import { CasaService } from "../service/CasaService";
import { SpesaService } from "../service/SpesaService";
import { ProblemaService } from "../service/ProblemaService";
import { TurnoService } from "../service/TurnoService";

import {
  CasaParams,
  InquilinoParams,
  QuotaParams,
  SpesaParams,
  TurnoParams,
  ProblemaParams,
} from "../types/params";
import {
  AssegnaTurnoDto,
  CreaTurnoDto,
  ModificaTurnoDto,
} from "../dto/TurnoDto";
import {
  AggiungiInquilinoDto,
  CreaCasaDto,
  ModificaRuoloDto,
} from "../dto/CasaDto";
import {
  CreaSpesaDto,
  ModificaSpesaDto,
  PareggiaContiDto,
} from "../dto/SpesaDto";
import {
  AggiornaPrioritaDto,
  AggiornaStatoDto,
  AssegnaProblemaDto,
  CreaProblemaDto,
} from "../dto/ProblemaDto";

// ─── Health ───────────────────────────────────────────────────────────────────
export function health(app: FastifyInstance) {
  app.get("/health", () => {
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
// POST /auth/verifica-codice   → Verifica codice di recupero (UC: Recupero Password - variante)
// POST /auth/reset-password    → Reset password (UC: Recupero Password - variante)

export function authRoutes(app: FastifyInstance) {
  const authController = new AuthController();

  app.post(
    "/auth/register",
    {
      config: { rateLimit: { max: 10, timeWindow: "1 minute" } },
    },
    authController.register,
  );
  app.post(
    "/auth/login",
    {
      config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
    },
    authController.login,
  );

  app.post(
    "/auth/recupera-password",
    {
      config: { rateLimit: { max: 3, timeWindow: "5 minutes" } },
    },
    authController.recuperaPassword,
  );
  app.post(
    "/auth/verifica-codice-recupero",
    {
      config: { rateLimit: { max: 5, timeWindow: "5 minutes" } },
    },
    authController.verificaCodiceRecupero,
  );
  app.post(
    "/auth/reset-password",
    {
      config: { rateLimit: { max: 5, timeWindow: "5 minutes" } },
    },
    authController.resetPassword,
  );

  app.post(
    "/auth/verifica-email",
    {
      config: { rateLimit: { max: 10, timeWindow: "5 minutes" } },
    },
    authController.verificaEmail,
  );
}

// ─── Debug/Protected (con authMiddleware) ─────────────────────────────────────
export function debugRoutes(app: FastifyInstance) {
  app.get(
    "/protected",
    { preHandler: authMiddleware },
    (request: FastifyRequest) => {
      const user = request.user;

      return {
        ok: true,
        message: "Accesso autorizzato",
        user,
      };
    },
  );
}

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

export function casaRoutes(app: FastifyInstance) {
  const casaService = new CasaService();
  const casaController = new CasaController(casaService);
  app.addHook("onRequest", authMiddleware);

  // CRUD casa
  app.post<{ Body: CreaCasaDto }>("/case", casaController.creaCasa);
  app.get("/case", casaController.getCase);
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getCasa,
  );
  app.delete<{ Params: CasaParams }>(
    "/case/:idCasa",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.eliminaCasa,
  );

  // Inquilini
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/inquilini",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getAllInquilini,
  );
  app.get<{ Params: InquilinoParams }>(
    "/case/:idCasa/inquilini/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getInquilino,
  );
  app.post<{ Params: CasaParams; Body: AggiungiInquilinoDto }>(
    "/case/:idCasa/inquilini",
    casaController.aggiungiInquilino,
  );
  app.delete<{ Params: InquilinoParams }>(
    "/case/:idCasa/inquilini/:idInquilino",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.rimuoviInquilino,
  );

  // Ruoli
  app.put<{ Params: InquilinoParams; Body: ModificaRuoloDto }>(
    "/case/:idCasa/inquilini/:idInquilino/ruolo",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.modificaRuolo,
  );

  // Link di invito
  app.get<{
    Params: CasaParams;
    Querystring?: { rigenera?: string | boolean };
  }>(
    "/case/:idCasa/invite-link",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.generaLink,
  );
}

// ─── Spese ────────────────────────────────────────────────────────────────────
//
// Controller: SpesaController
// Boundary:   SpeseScreens, DashboardScreen
//
// GET    /case/:idCasa/spese                            → Lista spese della casa (con filtri opzionali per periodo/stato)
// GET    /case/:idCasa/spese/:idSpesa                        → Dettaglio di una singola spesa
// POST   /case/:idCasa/spese                            → Crea una nuova spesa e calcola le quote (UC: Aggiunta Nuova Spesa)
// PUT    /case/:idCasa/spese/:idSpesa                        → Modifica una spesa esistente (solo owner spesa)
// DELETE /case/:idCasa/spese/:idSpesa                        → Elimina una spesa (solo owner spesa)
//
// GET    /case/:idCasa/spese/:idSpesa/quote                  → Ripartizione quote della spesa (UC: Aggiunta Nuova Spesa)
// GET    /case/:idCasa/spese/:idSpesa/quote/:idQuota         → Dettaglio di una singola quota
// POST   /case/:idCasa/spese/:idSpesa/quote/:idQuota/paga    → Registra il pagamento di una quota (UC: Pagamento Quota)
//
// POST   /case/:idCasa/spese/pareggia                   → Pareggio totale dei conti (UC: Pagamento Quota - variante)
//
// GET    /case/:idCasa/saldo                            → Saldo netto dell'utente nella casa
// GET    /case/:idCasa/credito                          → Credito totale dell'utente
// GET    /case/:idCasa/debito                           → Debito totale dell'utente
// GET    /case/:idCasa/credito/:idInquilino             → Credito verso un singolo inquilino
// GET    /case/:idCasa/debito/:idInquilino              → Debito verso un singolo inquilino

export function speseRoutes(app: FastifyInstance) {
  const speseService = new SpesaService();
  const speseController = new SpesaController(speseService);
  app.addHook("onRequest", authMiddleware);

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
  app.post<{ Params: CasaParams; Body: CreaSpesaDto }>(
    "/case/:idCasa/spese",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.addSpesa,
  );
  app.put<{ Params: SpesaParams; Body: ModificaSpesaDto }>(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.updateSpesa,
  );
  app.delete<{ Params: SpesaParams }>(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.deleteSpesa,
  );

  // Quote
  app.get<{ Params: SpesaParams }>(
    "/case/:idCasa/spese/:idSpesa/quote",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDivisioneSpese,
  );
  app.get<{ Params: QuotaParams }>(
    "/case/:idCasa/spese/:idSpesa/quote/:idQuota",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getQuota,
  );
  app.post<{ Params: QuotaParams }>(
    "/case/:idCasa/spese/:idSpesa/quote/:idQuota/paga",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.pagaQuota,
  );

  // Pareggio totale
  app.post<{ Params: CasaParams; Body: PareggiaContiDto }>(
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
  app.get<{ Params: InquilinoParams }>(
    "/case/:idCasa/credito/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getCreditoVersoUtente,
  );
  app.get<{ Params: InquilinoParams }>(
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
// PUT    /case/:idCasa/turni/:idTurno/autoassegna       → Assegna il turno a sé stessi (Inquilino)
// PUT    /case/:idCasa/turni/:idTurno/assegna           → Assegna il turno ad Inquilino (solo HomeAdmin)
// PATCH  /case/:idCasa/turni/:idTurno/rotazione         → Attiva/disattiva la rotazione automatica (solo HomeAdmin)
// POST   /case/:idCasa/turni/:idTurno/completa          → Marca il turno come completato e aggiorna la prossima scadenza

export function turniRoutes(app: FastifyInstance) {
  const turniService = new TurnoService();
  const turnoController = new TurnoController(turniService);
  app.addHook("onRequest", authMiddleware);

  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/turni",
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
// GET    /case/:idCasa/problemi/:idProblema                             → Dettaglio di un singolo problema
// POST   /case/:idCasa/problemi                                         → Segnala un nuovo problema (UC: Segnalazione Problema)
// DELETE /case/:idCasa/problemi/:idProblema                             → Elimina un problema (solo HomeAdmin)
// PUT    /case/:idCasa/turni/:idTurno/autoassegna                       → Assegna/de-assegna il problema a sé stessi (Inquilino)
// PUT    /case/:idCasa/problemi/:idProblema/assegna                     → Assegna/de-assegna il problema ad Inquilino (solo HomeAdmin)
// PATCH  /case/:idCasa/problemi/:idProblema/stato                       → Aggiorna lo stato (Segnalato → Assegnato → Risolto)
// PATCH  /case/:idCasa/problemi/:idProblema/priorita                    → Aggiorna la priorità (Urgente / Media / Bassa)

export function problemiRoutes(app: FastifyInstance) {
  const problemiService = new ProblemaService();
  const problemaController = new ProblemaController(problemiService);
  app.addHook("onRequest", authMiddleware);

  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/problemi",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.getAllProblemi,
  );
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/problemi/non-risolti",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.getProblemiNonRisolti,
  );
  app.get<{ Params: ProblemaParams }>(
    "/case/:idCasa/problemi/:idProblema",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.getProblema,
  );
  app.post<{ Params: CasaParams; Body: CreaProblemaDto }>(
    "/case/:idCasa/problemi",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.segnalaProblema,
  );
  app.delete<{ Params: ProblemaParams }>(
    "/case/:idCasa/problemi/:idProblema",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    problemaController.eliminaProblema,
  );
  app.put<{ Params: ProblemaParams }>(
    "/case/:idCasa/problemi/:idProblema/autoassegna",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.autoassegnaProblema,
  );
  app.put<{ Params: ProblemaParams; Body: AssegnaProblemaDto }>(
    "/case/:idCasa/problemi/:idProblema/assegna",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    problemaController.assegnaProblema,
  );
  app.patch<{ Params: ProblemaParams; Body: AggiornaStatoDto }>(
    "/case/:idCasa/problemi/:idProblema/stato",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.aggiornaStato,
  );
  app.patch<{ Params: ProblemaParams; Body: AggiornaPrioritaDto }>(
    "/case/:idCasa/problemi/:idProblema/priorita",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.aggiornaPriorita,
  );
}
