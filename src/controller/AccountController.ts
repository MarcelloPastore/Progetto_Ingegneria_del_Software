import { FastifyReply, FastifyRequest } from "fastify";
import { AccountService } from "../service/AccountService";
import { ModificaUsernameDto, ModificaEmailDto } from "../dto/AccountDto";
import { sendErrorReply } from "../utils/errorReply";

export class AccountController {
  constructor(private readonly accountService: AccountService) {}

  private handleFailure(reply: FastifyReply, error: unknown) {
    return sendErrorReply(reply, error);
  }

  getProfilo = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const profilo = await this.accountService.getProfilo(
        request.user.idUtente,
      );
      return reply.status(200).send(profilo);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  modificaUsername = async (
    request: FastifyRequest<{ Body: ModificaUsernameDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaUsernameDto.parse(request.body);
      const profilo = await this.accountService.modificaUsername(
        request.user.idUtente,
        dto,
      );
      return reply.status(200).send({
        message: "Username modificato con successo.",
        profilo,
      });
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  modificaEmail = async (
    request: FastifyRequest<{ Body: ModificaEmailDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaEmailDto.parse(request.body);
      const result = await this.accountService.modificaEmail(
        request.user.idUtente,
        dto,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  eliminaAccount = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const result = await this.accountService.eliminaAccount(
        request.user.idUtente,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };
}
