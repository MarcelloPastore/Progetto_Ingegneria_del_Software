import Fastify from "fastify";
import { connectDB } from "./src/config/db";
import { env } from "./src/config/env";

import {
  registerInfrastructure,
  registerApiRoutes,
} from "./src/utils/appBootstrap";

const app = Fastify({ logger: true, bodyLimit: 1_048_576 });

void (async () => {
  try {
    await connectDB();
    await registerInfrastructure(app, {
      jwtSecret: env.JWT_SECRET,
      jwtAccessTtl: env.JWT_ACCESS_TTL,
    });
    await registerApiRoutes(app);
    await app.listen({ host: "0.0.0.0", port: env.PORT });
  } catch (err) {
    console.error("Errore durante l'avvio:", err);
    process.exit(1);
  }
})();
