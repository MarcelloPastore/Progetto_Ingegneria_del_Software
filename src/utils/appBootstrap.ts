import type { FastifyInstance } from "fastify";
import fastifyJwt from "@fastify/jwt";
import fastifyHelmet from "@fastify/helmet";
import fastifyRateLimit from "@fastify/rate-limit";
import {
  authRoutes,
  casaRoutes,
  health,
  //debugRoutes,
  speseRoutes,
  turniRoutes,
  scadenzeRoutes,
  problemiRoutes,
  accountRoutes,
} from "../config/routes";

type InfrastructureOptions = {
  jwtSecret: string;
  jwtAccessTtl: string;
};

export async function registerInfrastructure(
  app: FastifyInstance,
  { jwtSecret, jwtAccessTtl }: InfrastructureOptions,
): Promise<void> {
  await app.register(fastifyHelmet, {
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: false,
    frameguard: { action: "deny" },
    referrerPolicy: { policy: "no-referrer" },
    hsts: {
      maxAge: 15552000,
      includeSubDomains: true,
      preload: false,
    },
  });

  await app.register(fastifyRateLimit, {
    global: true,
    max: 120,
    timeWindow: "1 minute",
  });

  await app.register(fastifyJwt, {
    secret: jwtSecret,
    sign: { expiresIn: jwtAccessTtl },
  });
}

export async function registerApiRoutes(
  app: FastifyInstance,
  prefix = "/api/v1",
): Promise<void> {
  await app.register(health, { prefix });
  await app.register(authRoutes, { prefix });
  await app.register(casaRoutes, { prefix });
  //await app.register(debugRoutes, { prefix });
  await app.register(turniRoutes, { prefix });
  await app.register(scadenzeRoutes, { prefix });
  await app.register(speseRoutes, { prefix });
  await app.register(problemiRoutes, { prefix });
  await app.register(accountRoutes, { prefix });
}
