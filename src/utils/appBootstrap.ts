import type { FastifyInstance } from "fastify";
import fastifyJwt from "@fastify/jwt";
import fastifyHelmet from "@fastify/helmet";
import fastifyRateLimit from "@fastify/rate-limit";
import {
  authRoutes,
  health,
  debugRoutes,
  speseRoutes,
  turniRoutes,
  //casaRoutes,
  problemiRoutes,
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

export function registerApiRoutes(
  app: FastifyInstance,
  prefix = "/api/v1",
): void {
  app.register(health, { prefix });
  app.register(authRoutes, { prefix });
  //app.register(casaRoutes, { prefix });
  app.register(debugRoutes, { prefix });
  app.register(turniRoutes, { prefix });
  app.register(speseRoutes, { prefix });
  app.register(problemiRoutes, { prefix });
}
