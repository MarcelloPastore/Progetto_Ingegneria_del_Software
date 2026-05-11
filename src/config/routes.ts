import { FastifyInstance } from "fastify";

import { authMiddleware } from "../middleware/AuthMiddleware";
import { SpeseController } from "../controller/SpeseController";
import { AuthController } from "../controller/AuthController";
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

export async function authRoutes(app: FastifyInstance) {
    const controller = new AuthController();

    app.post('/auth/register', controller.register);
    app.post('/auth/login', controller.login);
    app.post('/auth/recupera-password', controller.recuperaPassword);
    app.get('/auth/verifica-email', controller.verificaEmail);
}

// ─── Casa ─────────────────────────────────────────────────────────────────────
/*
export async function casaRoutes(app: FastifyInstance) {
    const controller = new CasaController();
    app.addHook('onRequest', authMiddleware);

    // CRUD casa
    app.post('/case', controller.creaCasa);
    app.get('/case', controller.getCase);
    app.get('/case/:idCasa', controller.getCasa);
    app.delete('/case/:idCasa', controller.eliminaCasa);

    // Inquilini
    app.get('/case/:idCasa/inquilini', controller.getInquilini);
    app.post('/case/:idCasa/inquilini', controller.aggiungiInquilino);
    app.delete('/case/:idCasa/inquilini/:idUtente', controller.rimuoviInquilino);

    // Ruoli
    app.put('/case/:idCasa/inquilini/:idUtente/ruolo', controller.modificaRuolo);

    // Link di invito
    app.get('/case/:idCasa/invite-link', controller.generaLink);
    // Adesione tramite link/codice (utente autenticato che si unisce)
    app.post('/case/join', controller.joinConLink);
}
*/
// ─── Spese ────────────────────────────────────────────────────────────────────

export async function speseRoutes(app: FastifyInstance) {
    const controller = new SpeseController();
    app.addHook('onRequest', authMiddleware);

    app.get('/case/:idCasa/spese', controller.getAll);
    app.get('/case/:idCasa/spese/:id', controller.getById);
    app.post('/case/:idCasa/spese', controller.create);
    app.put('/case/:idCasa/spese/:id', controller.update);
    app.delete('/case/:idCasa/spese/:id', controller.delete);

    // Quote
    app.get('/case/:idCasa/spese/:id/quote', controller.getDivisioneSpese);
    app.post('/case/:idCasa/spese/:id/quote/:idQuota/paga', controller.pagaQuota);

    // Pareggio totale (pareggia i conti)
    app.post('/case/:idCasa/spese/pareggia', controller.pareggiaConti);
}

// ─── Turni ────────────────────────────────────────────────────────────────────
/*
export async function turniRoutes(app: FastifyInstance) {
    const controller = new TurnoController();
    app.addHook('onRequest', authMiddleware);

    app.get('/case/:idCasa/turni', controller.getTurni);
    app.post('/case/:idCasa/turni', controller.creaTurno);
    app.delete('/case/:idCasa/turni/:idTurno', controller.eliminaTurno);

    // Assegnazione
    app.put('/case/:idCasa/turni/:idTurno/assegna', controller.assegnaTurno);

    // Toggle rotazione automatica
    app.patch('/case/:idCasa/turni/:idTurno/rotazione', controller.toggleRotazioneTurni);

    // Completamento turno (marca come eseguito e aggiorna prossima scadenza)
    app.post('/case/:idCasa/turni/:idTurno/completa', controller.completaTurno);
}
*/
// ─── Problemi ─────────────────────────────────────────────────────────────────
/*
export async function problemiRoutes(app: FastifyInstance) {
    const controller = new ProblemaController();
    app.addHook('onRequest', authMiddleware);

    app.get('/case/:idCasa/problemi', controller.getProblemi);
    app.post('/case/:idCasa/problemi', controller.segnalaProblema);
    app.delete('/case/:idCasa/problemi/:idProblema', controller.eliminaProblema);

    // Assegnazione e stato
    app.put('/case/:idCasa/problemi/:idProblema/assegna', controller.assegnaProblema);
    app.patch('/case/:idCasa/problemi/:idProblema/stato', controller.aggiornaStato);
    app.patch('/case/:idCasa/problemi/:idProblema/priorita', controller.aggiornaPriorita);
}
*/