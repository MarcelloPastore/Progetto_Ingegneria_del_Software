declare module 'fastify' {
    interface FastifyRequest {
        user: {
            idUtente: string;
            ruoloCasa?: Ruolo;
        };
    }
}

export {};