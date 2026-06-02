import { FastifyInstance } from "fastify";
import { Ruolo } from "@prisma/client";

import { requireRole } from "../middleware/RoleMiddleware";
import { authMiddleware } from "../middleware/AuthMiddleware";

import { AuthController } from "../controller/AuthController";
import { CasaController } from "../controller/CasaController";
import { SpesaController } from "../controller/SpesaController";
import { ProblemaController } from "../controller/ProblemaController";
import { TurnoController } from "../controller/TurnoController";
import { ScadenzaController } from "../controller/ScadenzaController";

import { CasaService } from "../service/CasaService";
import { SpesaService } from "../service/SpesaService";
import { ProblemaService } from "../service/ProblemaService";
import { TurnoService } from "../service/TurnoService";
import { ScadenzaService } from "../service/ScadenzaService";

/* eslint-disable @typescript-eslint/no-unused-vars -- usati nella documentazione */
import {
  CasaParams,
  InquilinoParams,
  QuotaParams,
  SpesaParams,
  TurnoParams,
  ProblemaParams,
  ScadenzaParams,
} from "../types/params";
import {
  AssegnaTurnoDto,
  CreaTurnoDto,
  ModificaTurnoDto,
  SaluteCasaDto,
  TurnoResponseDto,
} from "../dto/TurnoDto";
import {
  AggiungiInquilinoDto,
  CreaCasaDto,
  ModificaCasaDto,
  CasaResponseDto,
  ModificaRuoloDto,
} from "../dto/CasaDto";
import {
  CreaSpesaDto,
  ModificaSpesaDto,
  PareggiaContiDto,
  SpesaResponseDto,
} from "../dto/SpesaDto";
import {
  AggiornaPrioritaDto,
  AggiornaStatoDto,
  AssegnaProblemaDto,
  CreaProblemaDto,
  ProblemaResponseDto,
} from "../dto/ProblemaDto";
import { RegisterData, PublicUser } from "../dto/auth.dto";
import { AssegnatarioInfoDto } from "../dto/AssegnatarioDto";
import {
  AggiornaRicorrenzaDto,
  CreaScadenzaDto,
  ModificaScadenzaDto,
  ScadenzaResponseDto,
} from "../dto/ScadenzaDto";
import {
  ModificaUsernameDto,
  ModificaEmailDto,
  ModificaPasswordDto,
  UserProfileDto,
} from "../dto/AccountDto";

/* eslint-enable @typescript-eslint/no-unused-vars */

// ─── Health ───────────────────────────────────────────────────────────────────
export function health(app: FastifyInstance) {
  /**
   * @api  HealthCheck
   * @route GET /health
   *
   * @summary Verifica se il backend è attivo.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.get("/health", () => {
    return { status: "ok" };
  });
}

// ─── Auth (no authMiddleware) ─────────────────────────────────────────────────
//
// Controller: AuthController
// Boundary: LoginScreens, RegisterScreens

export function authRoutes(app: FastifyInstance) {
  const authController = new AuthController();

  /**
   * @api  RegisterUser
   * @route POST /auth/register
   *
   * @summary Registra un nuovo utente.
   *
   * @see {@link RegisterData}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post(
    "/auth/register",
    {
      config: { rateLimit: { max: 10, timeWindow: "1 minute" } },
    },
    authController.register,
  );
  /**
   * @api  LoginUser
   * @route POST /auth/login
   *
   * @summary Esegue il login e restituisce un token JWT.
   *
   * @see {@link PublicUser}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post(
    "/auth/login",
    {
      config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
    },
    authController.login,
  );

  /**
   * @api  RecuperaPassword
   * @route POST /auth/recupera-password
   *
   * @summary Invia un codice di recupero via email.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post(
    "/auth/recupera-password",
    {
      config: { rateLimit: { max: 3, timeWindow: "5 minutes" } },
    },
    authController.recuperaPassword,
  );
  /**
   * @api  VerificaCodiceRecupero
   * @route POST /auth/verifica-codice-recupero
   *
   * @summary Verifica il codice di recupero ricevuto via email.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post(
    "/auth/verifica-codice-recupero",
    {
      config: { rateLimit: { max: 5, timeWindow: "5 minutes" } },
    },
    authController.verificaCodiceRecupero,
  );
  /**
   * @api  ResetPassword
   * @route POST /auth/reset-password
   *
   * @summary Reimposta la password dell'utente.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post(
    "/auth/reset-password",
    {
      config: { rateLimit: { max: 5, timeWindow: "5 minutes" } },
    },
    authController.resetPassword,
  );

  /**
   * @api  VerificaEmail
   * @route POST /auth/verifica-email
   *
   * @summary Verifica e attiva l'account tramite link di verifica.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post(
    "/auth/verifica-email",
    {
      config: { rateLimit: { max: 10, timeWindow: "5 minutes" } },
    },
    authController.verificaEmail,
  );
}

/* ─── Debug/Protected (con authMiddleware) ─────────────────────────────────────
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
*/

// ─── Hub Casa ─────────────────────────────────────────────────────────────────
//
// Controller: CasaController
// Boundary: HubCasaScreens

export function casaRoutes(app: FastifyInstance) {
  const casaService = new CasaService();
  const casaController = new CasaController(casaService);
  app.addHook("onRequest", authMiddleware);

  /**
   * @api  CreaCasa
   * @route POST /case
   *
   * @summary Crea una nuova casa e genera un link di invito.
   *
   * @see {@link CreaCasaDto}
   * @see {@link CasaResponseDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post<{ Body: CreaCasaDto }>(
    "/case",
    {
      config: { rateLimit: { max: 1, timeWindow: "1 minute" } },
    },
    casaController.creaCasa,
  );
  /**
   * @api  GetCase
   * @route GET /case
   *
   * @summary Ottiene la lista delle case di cui l'utente fa parte.
   *
   * @see {@link CasaResponseDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.get(
    "/case",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getCase,
  );
  /**
   * @api  GetCasa
   * @route GET /case/:idCasa
   *
   * @summary Ottiene i dettagli di una singola casa.
   *
   * @see {@link CasaResponseDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getCasa,
  );
  /**
   * @api  ModificaCasa
   * @route PUT /case/:idCasa
   *
   * @summary Modifica le informazioni di una casa. Solo per HomeAdmin.
   *
   * @see {@link ModificaCasaDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: CasaParams; Body: ModificaCasaDto }>(
    "/case/:idCasa",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.modificaCasa,
  );
  /**
   * @api  EliminaCasa
   * @route DELETE /case/:idCasa
   *
   * @summary Elimina una casa. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.delete<{ Params: CasaParams }>(
    "/case/:idCasa",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.eliminaCasa,
  );
  /**
   * @api  GetAllInquilini
   * @route GET /case/:idCasa/inquilini
   *
   * @summary Ottiene la lista degli inquilini della casa.
   *
   * @see {@link AssegnatarioInfoDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/inquilini",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getAllInquilini,
  );
  /**
   * @api  GetInquilino
   * @route GET /case/:idCasa/inquilini/:idInquilino
   *
   * @summary Ottiene i dettagli di un singolo inquilino.
   *
   * @see {@link AssegnatarioInfoDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.get<{ Params: InquilinoParams }>(
    "/case/:idCasa/inquilini/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    casaController.getInquilino,
  );
  /**
   * @api  AggiungiInquilino
   * @route POST /case/:idCasa/inquilini
   *
   * @summary Aggiunge il chiamante a una casa tramite link di invito.
   *
   * @see {@link AggiungiInquilinoDto}
   * @see {@link AssegnatarioInfoDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.post<{ Params: CasaParams; Body: AggiungiInquilinoDto }>(
    "/case/:idCasa/inquilini",
    {
      config: { rateLimit: { max: 1, timeWindow: "1 minute" } },
    },
    casaController.aggiungiInquilino,
  );
  /**
   * @api  RimuoviInquilino
   * @route DELETE /case/:idCasa/inquilini/:idInquilino
   *
   * @summary Rimuove un inquilino dalla casa. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.delete<{ Params: InquilinoParams }>(
    "/case/:idCasa/inquilini/:idInquilino",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.rimuoviInquilino,
  );
  /**
   * @api  ModificaRuoloInquilino
   * @route PUT /case/:idCasa/inquilini/:idInquilino/ruolo
   *
   * @summary Modifica il ruolo di un inquilino. Solo per HomeAdmin.
   *
   * @see {@link ModificaRuoloDto}
   * @see {@link AssegnatarioInfoDto}
   *
   * @version 1.0.0
   * @author MLorenzo Tedino
   */
  app.put<{ Params: InquilinoParams; Body: ModificaRuoloDto }>(
    "/case/:idCasa/inquilini/:idInquilino/ruolo",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.modificaRuoloInquilino,
  );
  /**
   * @api  GeneraLink
   * @route GET /case/:idCasa/invite-link
   *
   * @summary Recupera o rigenera il link di invito della casa. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   */
  app.get<{
    Params: CasaParams;
    Querystring?: { rigenera?: string | boolean };
  }>(
    "/case/:idCasa/invite-link",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    casaController.generaLink,
  );
  /**
   * @api SelectCasa
   * @route POST /case/:idCasa/select
   *
   * @summary Cambia la casa attiva dell'utente e aggiorna il token con idCasa e ruolo.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: CasaParams }>(
    "/case/:idCasa/select",
    {
      config: { rateLimit: { max: 1, timeWindow: "1 minute" } },
    },
    casaController.selectCasa,
  );
}

// ─── Spese ────────────────────────────────────────────────────────────────────
//
// Controller: SpesaController
// Boundary: SpeseScreens, DashboardScreen

export function speseRoutes(app: FastifyInstance) {
  const speseService = new SpesaService();
  const speseController = new SpesaController(speseService);
  app.addHook("onRequest", authMiddleware);

  /**
   * @api  GetAllSpese
   * @route GET /case/:idCasa/spese
   *
   * @summary Ottiene la lista delle spese della casa.
   *
   * @see {@link SpesaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/spese",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getAllSpese,
  );
  /**
   * @api  GetSpesa
   * @route GET /case/:idCasa/spese/:idSpesa
   *
   * @summary Ottiene i dettagli di una singola spesa.
   *
   * @see {@link SpesaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: SpesaParams }>(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getSpesa,
  );
  /**
   * @api  AddSpesa
   * @route POST /case/:idCasa/spese
   *
   * @summary Crea una nuova spesa e calcola le quote.
   *
   * @see {@link CreaSpesaDto}
   * @see {@link SpesaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: CasaParams; Body: CreaSpesaDto }>(
    "/case/:idCasa/spese",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.addSpesa,
  );
  /**
   * @api  UpdateSpesa
   * @route PUT /case/:idCasa/spese/:idSpesa
   *
   * @summary Modifica una spesa esistente.
   *
   * @see {@link ModificaSpesaDto}
   * @see {@link SpesaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: SpesaParams; Body: ModificaSpesaDto }>(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.updateSpesa,
  );
  /**
   * @api  DeleteSpesa
   * @route DELETE /case/:idCasa/spese/:idSpesa
   *
   * @summary Elimina una spesa.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.delete<{ Params: SpesaParams }>(
    "/case/:idCasa/spese/:idSpesa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.deleteSpesa,
  );
  /**
   * @api  GetDivisioneSpese
   * @route GET /case/:idCasa/spese/:idSpesa/quote
   *
   * @summary Ottiene la ripartizione delle quote della spesa.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: SpesaParams }>(
    "/case/:idCasa/spese/:idSpesa/quote",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDivisioneSpese,
  );
  /**
   * @api  GetQuota
   * @route GET /case/:idCasa/spese/:idSpesa/quote/:idQuota
   *
   * @summary Ottiene i dettagli di una singola quota.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: QuotaParams }>(
    "/case/:idCasa/spese/:idSpesa/quote/:idQuota",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getQuota,
  );
  /**
   * @api  PagaQuota
   * @route POST /case/:idCasa/spese/:idSpesa/quote/:idQuota/paga
   *
   * @summary Registra il pagamento di una quota.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: QuotaParams }>(
    "/case/:idCasa/spese/:idSpesa/quote/:idQuota/paga",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.pagaQuota,
  );
  /**
   * @api  PareggiaConti
   * @route POST /case/:idCasa/spese/pareggia
   *
   * @summary Effettua il pareggio totale dei debiti del richiedente verso uno o più inquilini (molteplici pagaQuota in una chiamata sola).
   *
   * @see {@link PareggiaContiDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: CasaParams; Body: PareggiaContiDto }>(
    "/case/:idCasa/spese/pareggia",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.pareggiaConti,
  );
  /**
   * @api  GetSaldo
   * @route GET /case/:idCasa/saldo
   *
   * @summary Ottiene il saldo netto dell'utente nella casa.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/saldo",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getSaldo,
  );
  /**
   * @api  GetCreditoTot
   * @route GET /case/:idCasa/credito
   *
   * @summary Ottiene il credito totale dell'utente.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/credito",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getCreditoTot,
  );
  /**
   * @api  GetDebitoTot
   * @route GET /case/:idCasa/debito
   *
   * @summary Ottiene il debito totale dell'utente.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/debito",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDebitoTot,
  );
  /**
   * @api  GetCreditoVersoUtente
   * @route GET /case/:idCasa/credito/:idInquilino
   *
   * @summary Ottiene il credito verso un singolo inquilino.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: InquilinoParams }>(
    "/case/:idCasa/credito/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getCreditoVersoUtente,
  );
  /**
   * @api  GetDebitoVersoUtente
   * @route GET /case/:idCasa/debito/:idInquilino
   *
   * @summary Ottiene il debito verso un singolo inquilino.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: InquilinoParams }>(
    "/case/:idCasa/debito/:idInquilino",
    { preHandler: requireRole(Ruolo.Inquilino) },
    speseController.getDebitoVersoUtente,
  );
}

// ─── Turni ────────────────────────────────────────────────────────────────────
//
// Controller: TurnoController
// Boundary: TurniScreens, DashboardScreen

export function turniRoutes(app: FastifyInstance) {
  const turniService = new TurnoService();
  const turnoController = new TurnoController(turniService);
  app.addHook("onRequest", authMiddleware);

  /**
   * @api  GetAllTurni
   * @route GET /case/:idCasa/turni
   *
   * @summary Ottiene la lista dei turni della casa.
   *
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/turni",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getAllTurni,
  );
  /**
   * @api  GetTurniOdierni
   * @route GET /case/:idCasa/turni/oggi
   *
   * @summary Ottiene solo i turni previsti per oggi.
   *
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/turni/oggi",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getTurniOdierni,
  );
  /**
   * @api  CreaTurno
   * @route POST /case/:idCasa/turni
   *
   * @summary Crea un nuovo turno con rotazione automatica.
   *
   * @see {@link CreaTurnoDto}
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: CasaParams; Body: CreaTurnoDto }>(
    "/case/:idCasa/turni",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.creaTurno,
  );
  /**
   * @api  GetTurno
   * @route GET /case/:idCasa/turni/:idTurno
   *
   * @summary Ottiene i dettagli di un singolo turno.
   *
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getTurno,
  );
  /**
   * @api  ModificaTurno
   * @route PUT /case/:idCasa/turni/:idTurno
   *
   * @summary Modifica un turno esistente. Solo per HomeAdmin.
   *
   * @see {@link ModificaTurnoDto}
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: TurnoParams; Body: ModificaTurnoDto }>(
    "/case/:idCasa/turni/:idTurno",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.modificaTurno,
  );
  /**
   * @api  EliminaTurno
   * @route DELETE /case/:idCasa/turni/:idTurno
   *
   * @summary Elimina un turno. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.delete<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.eliminaTurno,
  );
  /**
   * @api  AutoassegnaTurno
   * @route PUT /case/:idCasa/turni/:idTurno/autoassegna
   *
   * @summary Assegna il turno all'utente stesso.
   *
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno/autoassegna",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.autoassegnaTurno,
  );
  /**
   * @api  AssegnaTurno
   * @route PUT /case/:idCasa/turni/:idTurno/assegna
   *
   * @summary Assegna il turno a un inquilino. Solo per HomeAdmin.
   *
   * @see {@link AssegnaTurnoDto}
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: TurnoParams; Body: AssegnaTurnoDto }>(
    "/case/:idCasa/turni/:idTurno/assegna",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    turnoController.assegnaTurno,
  );
  /**
   * @api  ToggleRotazioneTurni
   * @route PATCH /case/:idCasa/turni/:idTurno/rotazione
   *
   * @summary Attiva o disattiva la rotazione automatica. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.patch<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno/rotazione",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    turnoController.toggleRotazioneTurni,
  );
  /**
   * @api  CompletaTurno
   * @route POST /case/:idCasa/turni/:idTurno/completa
   *
   * @summary Marca il turno come completato e aggiorna la prossima scadenza.
   *
   * @see {@link TurnoResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: TurnoParams }>(
    "/case/:idCasa/turni/:idTurno/completa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.completaTurno,
  );
  /**
   * @api  GiorniDallUltimaPulizia
   * @route GET /case/:idCasa/turni/salute-casa
   *
   * @summary Restituisce per ogni turno il numero di giorni trascorsi dalla dataUltimaPulizia. Se dataUltimaPulizia è null, per quel turno viene restituito null.
   *
   * @see {@link SaluteCasaDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/turni/salute-casa",
    { preHandler: requireRole(Ruolo.Inquilino) },
    turnoController.getGiorniDallUltimaPulizia,
  );
}

// ─── Problemi ─────────────────────────────────────────────────────────────────
//
// Controller: ProblemaController
// Boundary: ProblemiScreens, DashboardScreen

export function problemiRoutes(app: FastifyInstance) {
  const problemiService = new ProblemaService();
  const problemaController = new ProblemaController(problemiService);
  app.addHook("onRequest", authMiddleware);

  /**
   * @api  GetAllProblemi
   * @route GET /case/:idCasa/problemi
   *
   * @summary Ottiene la lista di tutti i problemi della casa.
   *
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/problemi",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.getAllProblemi,
  );
  /**
   * @api  GetProblemiNonRisolti
   * @route GET /case/:idCasa/problemi/non-risolti
   *
   * @summary Ottiene solo i problemi non risolti della casa.
   *
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/problemi/non-risolti",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.getProblemiNonRisolti,
  );
  /**
   * @api  GetProblema
   * @route GET /case/:idCasa/problemi/:idProblema
   *
   * @summary Ottiene i dettagli di un singolo problema.
   *
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: ProblemaParams }>(
    "/case/:idCasa/problemi/:idProblema",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.getProblema,
  );
  /**
   * @api  SegnalaProblema
   * @route POST /case/:idCasa/problemi
   *
   * @summary Segnala un nuovo problema nella casa.
   *
   * @see {@link CreaProblemaDto}
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: CasaParams; Body: CreaProblemaDto }>(
    "/case/:idCasa/problemi",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.segnalaProblema,
  );
  /**
   * @api  EliminaProblema
   * @route DELETE /case/:idCasa/problemi/:idProblema
   *
   * @summary Elimina un problema. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.delete<{ Params: ProblemaParams }>(
    "/case/:idCasa/problemi/:idProblema",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    problemaController.eliminaProblema,
  );
  /**
   * @api  AutoassegnaProblema
   * @route PUT /case/:idCasa/problemi/:idProblema/autoassegna
   *
   * @summary Assegna il problema all'utente stesso.
   *
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: ProblemaParams }>(
    "/case/:idCasa/problemi/:idProblema/autoassegna",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.autoassegnaProblema,
  );
  /**
   * @api  AssegnaProblema
   * @route PUT /case/:idCasa/problemi/:idProblema/assegna
   *
   * @summary Assegna il problema a un inquilino. Solo per HomeAdmin.
   *
   * @see {@link AssegnaProblemaDto}
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: ProblemaParams; Body: AssegnaProblemaDto }>(
    "/case/:idCasa/problemi/:idProblema/assegna",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    problemaController.assegnaProblema,
  );
  /**
   * @api  AggiornaStatoProblema
   * @route PATCH /case/:idCasa/problemi/:idProblema/stato
   *
   * @summary Aggiorna lo stato di un singolo problema all'interno di una casa. Se lo stato viene impostato come Risolto, il problema viene chiuso.
   *
   * @see {@link AggiornaStatoDto}
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.patch<{ Params: ProblemaParams; Body: AggiornaStatoDto }>(
    "/case/:idCasa/problemi/:idProblema/stato",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.aggiornaStato,
  );
  /**
   * @api  AggiornaPrioritaProblema
   * @route PATCH /case/:idCasa/problemi/:idProblema/priorita
   *
   * @summary Aggiorna la priorità di un singolo problema all'interno di una casa.
   *
   * @see {@link AggiornaPrioritaDto}
   * @see {@link ProblemaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.patch<{ Params: ProblemaParams; Body: AggiornaPrioritaDto }>(
    "/case/:idCasa/problemi/:idProblema/priorita",
    { preHandler: requireRole(Ruolo.Inquilino) },
    problemaController.aggiornaPriorita,
  );
}

// ─── Scadenze ─────────────────────────────────────────────────────────────────
//
// Controller: ScadenzaController
// Boundary: ScadenzeScreens, DashboardScreen

export function scadenzeRoutes(app: FastifyInstance) {
  const scadenzaService = new ScadenzaService();
  const scadenzaController = new ScadenzaController(scadenzaService);
  app.addHook("onRequest", authMiddleware);

  /**
   * @api  GetScadenze
   * @route GET /case/:idCasa/scadenze
   *
   * @summary Ottiene la lista delle scadenze della casa.
   *
   * @see {@link ScadenzaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: CasaParams }>(
    "/case/:idCasa/scadenze",
    { preHandler: requireRole(Ruolo.Inquilino) },
    scadenzaController.getScadenze,
  );
  /**
   * @api  GetScadenza
   * @route GET /case/:idCasa/scadenze/:idScadenza
   *
   * @summary Ottiene i dettagli di una singola scadenza.
   *
   * @see {@link ScadenzaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.get<{ Params: ScadenzaParams }>(
    "/case/:idCasa/scadenze/:idScadenza",
    { preHandler: requireRole(Ruolo.Inquilino) },
    scadenzaController.getScadenza,
  );
  /**
   * @api  CreaScadenza
   * @route POST /case/:idCasa/scadenze
   *
   * @summary Crea una nuova scadenza nella casa.
   *
   * @see {@link CreaScadenzaDto}
   * @see {@link ScadenzaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.post<{ Params: CasaParams; Body: CreaScadenzaDto }>(
    "/case/:idCasa/scadenze",
    { preHandler: requireRole(Ruolo.Inquilino) },
    scadenzaController.creaScadenza,
  );
  /**
   * @api  ModificaScadenza
   * @route PUT /case/:idCasa/scadenze/:idScadenza
   *
   * @summary Modifica una scadenza esistente.
   *
   * @see {@link ModificaScadenzaDto}
   * @see {@link ScadenzaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.put<{ Params: ScadenzaParams; Body: ModificaScadenzaDto }>(
    "/case/:idCasa/scadenze/:idScadenza",
    { preHandler: requireRole(Ruolo.Inquilino) },
    scadenzaController.modificaScadenza,
  );
  /**
   * @api  EliminaScadenza
   * @route DELETE /case/:idCasa/scadenze/:idScadenza
   *
   * @summary Elimina una scadenza. Solo per HomeAdmin.
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.delete<{ Params: ScadenzaParams }>(
    "/case/:idCasa/scadenze/:idScadenza",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    scadenzaController.eliminaScadenza,
  );

  /**
   * @api  AggiornaRicorrenza
   * @route PATCH /case/:idCasa/scadenze/:idScadenza/ricorrenza
   *
   * @summary Attiva o disattiva la ricorrenza di una scadenza. Solo per HomeAdmin.
   *
   * @see {@link AggiornaRicorrenzaDto}
   * @see {@link ScadenzaResponseDto}
   *
   * @version 1.0.0
   * @author Mauro Cavasinni
   */
  app.patch<{ Params: ScadenzaParams; Body: AggiornaRicorrenzaDto }>(
    "/case/:idCasa/scadenze/:idScadenza/ricorrenza",
    { preHandler: requireRole(Ruolo.HomeAdmin) },
    scadenzaController.aggiornaRicorrenza,
  );
}

// ─── Account ──────────────────────────────────────────────────────────────────
//
// Controller: AccountController
// Boundary: AccountScreens

/*
export function accountRoutes(app: FastifyInstance) {
  const accountService = new AccountService();
  const accountController = new AccountController(accountService);
  app.addHook("onRequest", authMiddleware);

  /!**
   * @api  GetProfilo
   * @route GET /account
   *
   * @summary Ottiene il profilo dell'utente autenticato.
   *
   * @see {@link UserProfileDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   *!/
  app.get(
      "/account",
      accountController.getProfilo,
  );

  /!**
   * @api  ModificaUsername
   * @route PATCH /account/username
   *
   * @summary Modifica lo username dell'utente autenticato.
   *
   * @see {@link ModificaUsernameDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   *!/
  app.patch<{ Body: ModificaUsernameDto }>(
      "/account/username",
      accountController.modificaUsername,
  );

  /!**
   * @api  ModificaEmail
   * @route PATCH /account/email
   *
   * @summary Modifica l'email dell'utente autenticato. Richiede verifica del nuovo indirizzo.
   *
   * @see {@link ModificaEmailDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   *!/
  app.patch<{ Body: ModificaEmailDto }>(
      "/account/email",
      accountController.modificaEmail,
  );

  /!**
   * @api  ModificaPassword
   * @route PATCH /account/password
   *
   * @summary Modifica la password dell'utente autenticato. Invalida le altre sessioni.
   *
   * @see {@link ModificaPasswordDto}
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   *!/
  app.patch<{ Body: ModificaPasswordDto }>(
      "/account/password",
      accountController.modificaPassword,
  );

  /!**
   * @api  EliminaAccount
   * @route DELETE /account
   *
   * @summary Elimina l'account dell'utente autenticato e anonimizza i dati personali.
   *
   * @version 1.0.0
   * @author Lorenzo Tedino
   *!/
  app.delete(
      "/account",
      accountController.eliminaAccount,
  );
}*/
