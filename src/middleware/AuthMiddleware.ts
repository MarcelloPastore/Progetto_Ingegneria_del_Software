import { FastifyRequest, FastifyReply } from "fastify";
import type { Ruolo } from "@prisma/client";
import { getJwt } from "../utils/jwt";
import { mapErrorToHttp } from "../errors/errorMapper";
import {
  MissingAuthTokenError,
  MalformedAuthorizationHeaderError,
  InvalidTokenPayloadError,
} from "../errors/appErrors";

const getBearerToken = (authorizationHeader?: string): string => {
  if (!authorizationHeader) {
    throw new MissingAuthTokenError();
  }

  const parts = authorizationHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") {
    throw new MalformedAuthorizationHeaderError();
  }

  return parts[1];
};

const getUserFromPayload = (payload: Record<string, unknown>) => {
  const idUtente = (payload["id"] ?? payload["idUtente"]) as string | undefined;
  const ruolo = (payload["role"] ?? payload["ruoloCasa"]) as Ruolo | undefined;
  const tokenType = payload["type"];

  if (!idUtente || (tokenType !== undefined && tokenType !== "access")) {
    throw new InvalidTokenPayloadError();
  }

  return { idUtente, ruoloCasa: ruolo };
};

export async function authMiddleware(
  req: FastifyRequest,
  rep: FastifyReply,
): Promise<void> {
  try {
    const token = getBearerToken(req.headers.authorization);
    const jwt = getJwt(req.server);
    const payload = jwt.verify(token) as Record<string, unknown>;

    req.user = getUserFromPayload(payload);
  } catch (error) {
    const mapped = mapErrorToHttp(error);
    const responsePayload: {
      error: string;
      details?: Record<string, string[]>;
    } = {
      error: mapped.message,
    };

    if (mapped.details) {
      responsePayload.details = mapped.details;
    }

    rep.code(mapped.statusCode).send(responsePayload);
  }
}
