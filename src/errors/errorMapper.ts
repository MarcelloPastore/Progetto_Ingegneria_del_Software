import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { HttpError } from "./httpErrors";

type HttpErrorPayload = {
  statusCode: number;
  message: string;
  code: string;
};

export function mapErrorToHttp(error: unknown): HttpErrorPayload {
  if (error instanceof HttpError) {
    return {
      statusCode: error.statusCode,
      message: error.message,
      code: error.code,
    };
  }

  if (error instanceof ZodError) {
    return {
      statusCode: 400,
      message: "Dati non validi",
      code: "BAD_REQUEST",
    };
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === "P2025") {
      return {
        statusCode: 404,
        message: "Risorsa non trovata",
        code: "NOT_FOUND",
      };
    }
  }

  return {
    statusCode: 500,
    message: "Errore interno del server",
    code: "INTERNAL_ERROR",
  };
}
