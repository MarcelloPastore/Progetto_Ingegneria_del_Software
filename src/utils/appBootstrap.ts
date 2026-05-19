import type { FastifyInstance } from "fastify";
import fastifyJwt from "@fastify/jwt";
import fastifyHelmet from "@fastify/helmet";
import fastifyRateLimit from "@fastify/rate-limit";
import { authRoutes, health, debugRoutes } from "../config/routes";

type InfrastructureOptions = {
  jwtSecret: string;
};

export function getRequiredEnv(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Variabile d'ambiente ${name} mancante`);
  }

  return value;
}

export async function registerInfrastructure(
  app: FastifyInstance,
  { jwtSecret }: InfrastructureOptions,
): Promise<void> {
  await app.register(fastifyHelmet, {
    // Backend API per client mobile/web: hardening header senza CSP HTML.
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
    sign: { expiresIn: process.env.JWT_ACCESS_TTL ?? "14d" },
  });
}

export async function registerApiRoutes(
  app: FastifyInstance,
  prefix = "/api/v1",
): Promise<void> {
  app.register(health, { prefix });
  app.register(authRoutes, { prefix });
  app.register(debugRoutes, { prefix });
}
