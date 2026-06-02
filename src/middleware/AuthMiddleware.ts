import { FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../config/db";
import { getJwt } from "../utils/jwt";
import { mapErrorToHttp } from "../errors/errorMapper";
import {
  MissingAuthTokenError,
  MalformedAuthorizationHeaderError,
  InvalidTokenPayloadError,
  AuthenticatedUserNotFoundError,
} from "../errors/appErrors";
import { Ruolo } from "@prisma/client";

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

const getUserFromPayload = (payload: unknown) => {
  if (typeof payload !== "object" || payload === null) {
    throw new InvalidTokenPayloadError();
  }

  const p = payload as Record<string, unknown>;
  const idValue = p.id ?? p.idUtente;
  const tokenType = p.type;
  const ruoloCasa = p.ruoloCasa;
  const idCasa = p.idCasa ?? p.casa ?? null;
  const idUtente =
    typeof idValue === "string" && idValue.length > 0 ? idValue : undefined;
  const tokenTypeStr = typeof tokenType === "string" ? tokenType : undefined;
  const ruoloCasaStr = typeof ruoloCasa === "string" ? ruoloCasa : undefined;
  const ruoloCasaValue = ruoloCasaStr
    ? (Ruolo[ruoloCasaStr as keyof typeof Ruolo] ?? undefined)
    : undefined;
  const idCasaStr =
    typeof idCasa === "string" && idCasa.length > 0 ? idCasa : null;

  if (!idUtente || (tokenTypeStr !== undefined && tokenTypeStr !== "access")) {
    throw new InvalidTokenPayloadError();
  }

  return { idUtente, ruoloCasa: ruoloCasaValue, idCasa: idCasaStr };
};

export async function authMiddleware(
  req: FastifyRequest,
  rep: FastifyReply,
): Promise<void> {
  try {
    const token = getBearerToken(req.headers.authorization);
    const jwt = getJwt(req.server);
    const payload = jwt.verify(token) as Record<string, unknown>;

    const { idUtente, ruoloCasa } = getUserFromPayload(payload);
    const user = await prisma.utente.findUnique({
      where: { id: idUtente },
      select: {
        id: true,
      },
    });

    if (!user) {
      const mapped = mapErrorToHttp(new AuthenticatedUserNotFoundError());
      const responsePayload: {
        error: string;
        details?: Record<string, string[]>;
      } = {
        error: mapped.message,
      };

      if (mapped.details) {
        responsePayload.details = mapped.details;
      }

      await rep.code(mapped.statusCode).send(responsePayload);
      return;
    }

    req.user = {
      idUtente: user.id,
      ruoloCasa,
    };
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

    await rep.code(mapped.statusCode).send(responsePayload);
  }
}
