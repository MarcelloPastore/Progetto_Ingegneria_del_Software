import { FastifyRequest, FastifyReply } from "fastify";
import { Ruolo } from "@prisma/client";
import { AuthService } from "../service/AuthService";
import { z } from "zod";
import { getJwt } from "../utils/jwt";

type RegisterData = Parameters<AuthService["register"]>[0];

const authService = new AuthService();
const RegisterSchema = z.object({
  email: z.email(),
  password: z.string().min(10).max(128),
  nome: z.string().min(1).max(100),
  cognome: z.string().min(1).max(100),
  ruolo: z.enum(Ruolo).optional(),
});

const LoginSchema = z.object({
  email: z.email(),
  password: z.string(),
});

export class AuthController {
  register = async (
    request: FastifyRequest<{ Body: RegisterData }>,
    reply: FastifyReply,
  ) => {
    const parsed = RegisterSchema.safeParse(request.body);
    if (!parsed.success) {
      const errorsMap = new Map<string, string[]>();
      parsed.error.issues.forEach((issue) => {
        const path = issue.path.join(".");
        if (!errorsMap.has(path)) {
          errorsMap.set(path, []);
        }
        errorsMap.get(path)!.push(issue.message);
      });
      const errors = Object.fromEntries(errorsMap);
      return reply.code(400).send({
        error: "Dati non validi",
        details: errors,
      });
    }

    try {
      const user = await authService.register(parsed.data);
      return reply.code(201).send({
        message: "Registrazione completata",
        userId: user.id,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      return reply.code(400).send({ error: message });
    }
  };

  login = async (request: FastifyRequest, reply: FastifyReply) => {
    const result = LoginSchema.safeParse(request.body);
    if (!result.success) {
      const errorsMap = new Map<string, string[]>();
      result.error.issues.forEach((issue) => {
        const path = issue.path.join(".");
        if (!errorsMap.has(path)) {
          errorsMap.set(path, []);
        }
        errorsMap.get(path)!.push(issue.message);
      });
      const errors = Object.fromEntries(errorsMap);
      return reply.code(400).send({
        error: "Dati non validi",
        details: errors,
      });
    }

    const { email, password } = result.data;

    try {
      const user = await authService.validateUser(email, password);

      if (!user) {
        return reply.code(401).send({ error: "Credenziali errate" });
      }

      const jwt = getJwt(request.server);
      const token = jwt.sign({
        id: user.id,
        role: user.ruolo,
        type: "access",
      });

      return reply.send({
        token,
        user: { id: user.id, nome: user.nome, ruolo: user.ruolo },
      });
    } catch {
      console.error("Errore login");
      return reply.code(500).send({ error: "Errore interno del server" });
    }
  };

  recuperaPassword = async () => {
    /* Implementa */
  };
  verificaEmail = async () => {
    /* Implementa */
  };
}
