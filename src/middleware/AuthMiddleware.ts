import { FastifyRequest, FastifyReply } from "fastify";
import type { Ruolo } from "@prisma/client";
import { getJwt } from "../utils/jwt";

export async function authMiddleware(
  req: FastifyRequest,
  rep: FastifyReply,
): Promise<void> {
  const auth = req.headers.authorization;
  if (!auth) {
    rep.code(401).send({ error: "Token mancante" });
    return;
  }

  const parts = auth.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") {
    rep.code(401).send({ error: "Intestazione Authorization malformata" });
    return;
  }

  const token = parts[1];

  try {
    const jwt = getJwt(req.server);
    const payload = jwt.verify(token) as Record<string, unknown>;

    const idUtente = (payload["id"] ?? payload["idUtente"]) as
      | string
      | undefined;
    const ruolo = (payload["role"] ?? payload["ruoloCasa"]) as
      | Ruolo
      | undefined;
    const tokenType = payload["type"];

    if (!idUtente || (tokenType !== undefined && tokenType !== "access")) {
      rep.code(401).send({ error: "Payload token non valido" });
      return;
    }

    req.user = {
      idUtente,
      ruoloCasa: ruolo,
    };
  } catch {
    rep.code(401).send({ error: "Token non valido" });
    return;
  }
}
