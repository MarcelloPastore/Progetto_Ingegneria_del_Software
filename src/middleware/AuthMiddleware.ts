import { FastifyRequest, FastifyReply } from "fastify";
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
  if (typeof payload !== "object" || payload === null) {
    throw new InvalidTokenPayloadError();
  }

  const p = payload as Record<string, unknown>;
  const idValue = p.id ?? p.idUtente;
  const tokenType = p.type;
  const idUtente =
    typeof idValue === "string" && idValue.length > 0 ? idValue : undefined;
  const tokenTypeStr = typeof tokenType === "string" ? tokenType : undefined;

  if (!idUtente || (tokenTypeStr !== undefined && tokenTypeStr !== "access")) {
    throw new InvalidTokenPayloadError();
  }

  return { idUtente };
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
