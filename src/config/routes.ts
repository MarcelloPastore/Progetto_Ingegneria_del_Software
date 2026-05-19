import { FastifyInstance, FastifyRequest } from "fastify";

import { AuthController } from "../controller/AuthController";
import { authMiddleware } from "../middleware/AuthMiddleware";

// ─── Health ───────────────────────────────────────────────────────────────────
export function health(app: FastifyInstance) {
  app.get("/health", () => {
    return { status: "ok" };
  });
}

// ─── Auth (no authMiddleware) ─────────────────────────────────────────────────
export function authRoutes(app: FastifyInstance) {
  const authController = new AuthController();

  app.post(
    "/auth/register",
    {
      config: { rateLimit: { max: 10, timeWindow: "1 minute" } },
    },
    authController.register,
  );
  app.post(
    "/auth/login",
    {
      config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
    },
    authController.login,
  );
  app.post("/auth/recupera-password", authController.recuperaPassword);
  app.post("/auth/verifica-email", authController.verificaEmail);
}

// ─── Debug/Protected (con authMiddleware) ─────────────────────────────────────
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
