import type { FastifyReply } from "fastify";
import { mapErrorToHttp } from "../errors/errorMapper";

export function sendErrorReply(reply: FastifyReply, error: unknown) {
  const mapped = mapErrorToHttp(error);
  const payload: {
    error: string;
    message: string;
    code: string;
    details?: Record<string, string[]>;
    stack?: string;
  } = {
    error: mapped.message,
    message: mapped.message,
    code: mapped.code,
  };

  if (mapped.details) {
    payload.details = mapped.details;
  }

  if (mapped.stack) {
    payload.stack = mapped.stack;
  }

  return reply.code(mapped.statusCode).send(payload);
}
