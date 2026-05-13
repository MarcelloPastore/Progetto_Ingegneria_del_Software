import { FastifyInstance } from "fastify";

import { authMiddleware } from "../middleware/AuthMiddleware";
import { AuthController } from "../controller/AuthController";
import { SpeseController } from "../controller/SpeseController";
import { CasaController } from "../controller/CasaController";
import { TurnoController } from "../controller/TurnoController";
import { ProblemaController } from "../controller/ProblemaController";

// ─── Health ───────────────────────────────────────────────────────────────────

export async function health(app: FastifyInstance) {
    app.get('/health', async () => {
        return { status: 'ok' };
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

export async function authRoutes(app: FastifyInstance) {
    const authController = new AuthController();

    app.post('/auth/register', authController.register);
    app.post('/auth/login', authController.login);
    app.post('/auth/recupera-password', authController.recuperaPassword);
    app.get('/auth/verifica-email', authController.verificaEmail);
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

export async function casaRoutes(app: FastifyInstance) {
    const casaController = new CasaController();
    app.addHook('onRequest', authMiddleware);

    // CRUD casa
    app.post('/case', casaController.creaCasa);
    app.get('/case', casaController.getCase);
    app.get('/case/:idCasa', casaController.getCasa);
    app.delete('/case/:idCasa', casaController.eliminaCasa);

    // Inquilini
    app.get('/case/:idCasa/inquilini', casaController.getAllInquilini);
    app.get('/case/:idCasa/inquilini/:idUtente', casaController.getInquilino)
    app.post('/case/:idCasa/inquilini', casaController.aggiungiInquilino);
    app.delete('/case/:idCasa/inquilini/:idUtente', casaController.rimuoviInquilino);

    // Ruoli
    app.put('/case/:idCasa/inquilini/:idUtente/ruolo', casaController.modificaRuolo);

    // Link di invito
    app.get('/case/:idCasa/invite-link', casaController.generaLink);
}

// ─── Spese ────────────────────────────────────────────────────────────────────
//
// Controller: SpeseController
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
    const speseController = new SpeseController();
    app.addHook('onRequest', authMiddleware);

    // CRUD spese
    app.get('/case/:idCasa/spese', speseController.getAllSpese);
    app.get('/case/:idCasa/spese/:id', speseController.getSpesa);
    app.post('/case/:idCasa/spese', speseController.addSpesa);
    app.put('/case/:idCasa/spese/:id', speseController.updateSpesa);
    app.delete('/case/:idCasa/spese/:id', speseController.deleteSpesa);

    // Quote
    app.get('/case/:idCasa/spese/:id/quote', speseController.getDivisioneSpese);
    app.post('/case/:idCasa/spese/:id/quote/:idQuota/paga', speseController.pagaQuota);

    // Pareggio totale
    app.post('/case/:idCasa/spese/pareggia', speseController.pareggiaConti);

    // Saldo, Credito e Debito
    app.get('/case/:idCasa/saldo', speseController.getSaldo);
    app.get('/case/:idCasa/credito', speseController.getCreditoTot);
    app.get('/case/:idCasa/debito', speseController.getDebitoTot);
    app.get('/case/:idCasa/credito/:idInquilino', speseController.getCreditoVersoUtente);
    app.get('/case/:idCasa/debito/:idInquilino', speseController.getDebitoVersoUtente);
}

// ─── Turni ────────────────────────────────────────────────────────────────────
//
// Controller: TurnoController
// Boundary:   TurniScreens, DashboardScreen
//
// GET    /case/:idCasa/turni                            → Lista turni della casa
// POST   /case/:idCasa/turni                            → Crea un nuovo turno (UC: Creazione Turno con Rotazione Automatica)
// GET    /case/:idCasa/turni/:idTurno                   → Dettaglio di un singolo turno
// PUT    /case/:idCasa/turni/:idTurno                   → Modifica un turno esistente (solo HomeAdmin)
// DELETE /case/:idCasa/turni/:idTurno                   → Elimina un turno (solo HomeAdmin)
//
// PUT    /case/:idCasa/turni/:idTurno/assegna           → Auto-assegnazione del turno a sé stessi (Inquilino)
// PATCH  /case/:idCasa/turni/:idTurno/rotazione         → Attiva/disattiva la rotazione automatica (solo HomeAdmin)
// POST   /case/:idCasa/turni/:idTurno/completa          → Marca il turno come completato e aggiorna la prossima scadenza

export async function turniRoutes(app: FastifyInstance) {
    const turnoController = new TurnoController();
    app.addHook('onRequest', authMiddleware);

    // CRUD turni
    app.get('/case/:idCasa/turni', turnoController.getAllTurni);
    app.post('/case/:idCasa/turni', turnoController.creaTurno);
    app.get('/case/:idCasa/turni/:idTurno', turnoController.getTurno);
    app.put('/case/:idCasa/turni/:idTurno', turnoController.modificaTurno);
    app.delete('/case/:idCasa/turni/:idTurno', turnoController.eliminaTurno);

    // Assegnazione e gestione
    app.put('/case/:idCasa/turni/:idTurno/assegna', turnoController.assegnaTurno);
    app.patch('/case/:idCasa/turni/:idTurno/rotazione', turnoController.toggleRotazioneTurni);
    app.post('/case/:idCasa/turni/:idTurno/completa', turnoController.completaTurno);
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

export async function problemiRoutes(app: FastifyInstance) {
    const problemaController = new ProblemaController();
    app.addHook('onRequest', authMiddleware);

    // CRUD problemi
    app.get('/case/:idCasa/problemi', problemaController.getAllProblemi);
    app.get('/case/:idCasa/problemi/non-risolti', problemaController.getProblemiNonRisolti);
    app.post('/case/:idCasa/problemi', problemaController.segnalaProblema);
    app.delete('/case/:idCasa/problemi/:idProblema', problemaController.eliminaProblema);

    // Assegnazione e aggiornamento
    app.put('/case/:idCasa/problemi/:idProblema/assegna', problemaController.assegnaProblema);
    app.patch('/case/:idCasa/problemi/:idProblema/stato', problemaController.aggiornaStato);
    app.patch('/case/:idCasa/problemi/:idProblema/priorita', problemaController.aggiornaPriorita);
}