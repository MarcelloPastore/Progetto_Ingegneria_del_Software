import { FastifyRequest, FastifyReply } from "fastify";
import { AuthService } from "../service/AuthService";
import { RegisterData } from "../dto/auth.dto";
import { getJwt } from "../utils/jwt";
import { mapErrorToHttp } from "../errors/errorMapper";

const authService = new AuthService();

export class AuthController {
  private handleAuthFailure(reply: FastifyReply, error: unknown) {
    const mapped = mapErrorToHttp(error);
    const payload: { error: string; details?: Record<string, string[]> } = {
      error: mapped.message,
    };

    if (mapped.details) {
      payload.details = mapped.details;
    }

    return reply.code(mapped.statusCode).send(payload);
  }

  register = async (
    request: FastifyRequest<{ Body: RegisterData }>,
    reply: FastifyReply,
  ) => {
    try {
      const result = await authService.registerWithValidation(request.body);
      return reply.code(201).send({
        message: result.message,
        userId: result.id,
      });
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };

  login = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const result = await authService.loginWithValidation(request.body);

      const { user } = result;

      const jwt = getJwt(request.server);
      const token = jwt.sign({
        id: user.id,
        type: "access",
      });

      return reply.send({
        token,
        user: {
          id: user.id,
          username: user.username,
          nome: user.nome,
        },
      });
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };

  recuperaPassword = async () => {
    /* Implementa */
  };
  verificaEmail = async () => {
    /* Implementa */
  };
}
