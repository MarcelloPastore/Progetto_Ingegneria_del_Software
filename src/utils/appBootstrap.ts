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
  void app.register(health, { prefix });
  void app.register(authRoutes, { prefix });
  //void app.register(casaRoutes, { prefix });
  void app.register(debugRoutes, { prefix });
  void app.register(turniRoutes, { prefix });
  void app.register(speseRoutes, { prefix });
  void app.register(problemiRoutes, { prefix });
}
