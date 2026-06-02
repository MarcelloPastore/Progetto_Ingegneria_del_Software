import type { Ruolo } from "@prisma/client";

declare module "fastify" {
  interface FastifyRequest {
    user: {
      idUtente: string;
      idCasa?: string | null;
      ruoloCasa?: Ruolo;
    };
  }
}

export {};
