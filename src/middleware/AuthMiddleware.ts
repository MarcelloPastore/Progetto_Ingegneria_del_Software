import { FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../config/db";
import { getJwt } from "../utils/jwt";
import { sendErrorReply } from "../utils/errorReply";
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
  const idUtente =
    typeof idValue === "string" && idValue.length > 0 ? idValue : undefined;
  const tokenTypeStr = typeof tokenType === "string" ? tokenType : undefined;
  const idCasaValue = p.idCasa ?? p.casa;
  const idCasaStr =
    typeof idCasaValue === "string" && idCasaValue.length > 0
      ? idCasaValue
      : null;
  const ruoloCasaValue = p.ruoloCasa;
  const ruoloCasa =
    typeof ruoloCasaValue === "string"
      ? (Ruolo[ruoloCasaValue as keyof typeof Ruolo] ?? undefined)
      : undefined;

  if (!idUtente || (tokenTypeStr !== undefined && tokenTypeStr !== "access")) {
    throw new InvalidTokenPayloadError();
  }

  if (idCasaStr && !ruoloCasa) {
    throw new InvalidTokenPayloadError();
  }

  return { idUtente, ruoloCasa, idCasa: idCasaStr };
};

export async function authMiddleware(
  req: FastifyRequest,
  rep: FastifyReply,
): Promise<void> {
  try {
    const token = getBearerToken(req.headers.authorization);
    const jwt = getJwt(req.server);
    const payload = jwt.verify(token) as Record<string, unknown>;

    const { idUtente, ruoloCasa, idCasa } = getUserFromPayload(payload);
    const user = await prisma.utente.findUnique({
      where: { id: idUtente },
      select: {
        id: true,
      },
    });

    if (!user) {
      await sendErrorReply(rep, new AuthenticatedUserNotFoundError());
      return;
    }

    req.user = {
      idUtente: user.id,
      ruoloCasa,
      idCasa,
    };
  } catch (error) {
    await sendErrorReply(rep, error);
  }
}
