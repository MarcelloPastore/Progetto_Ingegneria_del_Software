import { FastifyReply, FastifyRequest } from "fastify";

import { CreaCasaDto, CreaCasaSchema } from "../dto/CasaDto";
import { CasaService } from "../service/CasaService";
import { CasaParams } from "../types/params";
import { mapErrorToHttp } from "../errors/errorMapper";

export class CasaController {
  constructor(private casaService = new CasaService()) {}

  /**
   * POST /case
   */
  creaCasa = async (
    request: FastifyRequest<{ Body: CreaCasaDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = CreaCasaSchema.parse(request.body);
      const casa = await this.casaService.creaCasa(dto, request.user.idUtente);
      return reply.status(201).send(casa);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case
   */
  getCase = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const caseUtente = await this.casaService.getCase(
        request.user.idUtente,
      );
      return reply.status(200).send({ case: caseUtente });
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case/:idCasa
   */
  getCasa = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const casa = await this.casaService.getCasa(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send(casa);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };
}
