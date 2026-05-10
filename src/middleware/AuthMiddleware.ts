import { FastifyRequest, FastifyReply } from 'fastify';
import jwt from 'jsonwebtoken';
import { Ruolo } from '../types/enums';

interface JwtPayload {
    idUtente:    string;
    ruoloCasa?: Ruolo;  //Il ruolo dipende dalla casa, ma averlo salvato sul token velocizza tutte le altre richieste.
    // Ho un'idea per il ruolo: viene caricato quando l'utente apre una dashboard.
    // Refresh all'accesso in una nuova casa.
}

export async function authMiddleware(
    req: FastifyRequest,
    rep: FastifyReply,
): Promise<void> {
    //TODO: Implementare logica di generazione, verifica e refresh token
}