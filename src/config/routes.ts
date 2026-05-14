import { FastifyInstance, FastifyRequest } from "fastify";

import { AuthController } from "../controller/AuthController";
import { authMiddleware } from "../middleware/AuthMiddleware";

// ─── Health ───────────────────────────────────────────────────────────────────
export async function health(app: FastifyInstance) {
  app.get("/health", async () => {
    return { status: "ok" };
  });
}

// ─── Auth (no authMiddleware) ─────────────────────────────────────────────────
export async function authRoutes(app: FastifyInstance) {
  const controller = new AuthController();

  app.post(
    "/auth/register",
    {
      config: { rateLimit: { max: 10, timeWindow: "1 minute" } },
    },
    controller.register,
  );
  app.post(
    "/auth/login",
    {
      config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
    },
    controller.login,
  );
  app.post("/auth/recupera-password", controller.recuperaPassword);
  app.get("/auth/verifica-email", controller.verificaEmail);
}

// ─── Debug/Protected (con authMiddleware) ─────────────────────────────────────
export async function debugRoutes(app: FastifyInstance) {
  app.get(
    "/protected",
    { preHandler: authMiddleware },
    async (request: FastifyRequest) => {
      const user = request.user;

      return {
        ok: true,
        message: "Accesso autorizzato",
        user,
      };
    },
  );
}
