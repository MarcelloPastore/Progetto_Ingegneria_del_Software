import { FastifyRequest, FastifyReply } from "fastify";
import { AuthService } from "../service/AuthService";
import { RegisterData, VerifyEmailData } from "../dto/auth.dto";
import { getJwt } from "../utils/jwt";
import { sendErrorReply } from "../utils/errorReply";

const authService = new AuthService();

export class AuthController {
  private handleAuthFailure(reply: FastifyReply, error: unknown) {
    return sendErrorReply(reply, error);
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
        idUtente: user.id,
        type: "access",
      });

      return reply.send({
        token,
        user: {
          idUtente: user.id,
          username: user.username,
          nome: user.nome,
        },
      });
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };

  recuperaPassword = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const result = await authService.requestPasswordResetWithValidation(
        request.body,
      );
      return reply.send(result);
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };

  verificaCodiceRecupero = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ) => {
    try {
      const result = await authService.verifyPasswordResetCodeWithValidation(
        request.body,
      );
      return reply.send(result);
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };

  resetPassword = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const result = await authService.resetPasswordWithValidation(
        request.body,
      );
      return reply.send(result);
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };
  emailVerificata = async (
    request: FastifyRequest<{ Querystring: { email: string } }>,
    reply: FastifyReply,
  ) => {
    try {
      const result = await authService.checkEmailVerificata(request.query.email);
      return reply.send(result);
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };

  verificaEmail = async (
    request: FastifyRequest<{
      Body?: VerifyEmailData;
      Querystring?: VerifyEmailData;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const payload = request.body ?? request.query;
      const result = await authService.verificaEmail(payload);
      return reply.send(result);
    } catch (error) {
      return this.handleAuthFailure(reply, error);
    }
  };
}
