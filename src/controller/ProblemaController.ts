import { FastifyReply, FastifyRequest } from "fastify";
import { ProblemaService } from "../service/ProblemaService";
import { CasaParams, ProblemaParams } from "../types/params";
import {
  AggiornaPrioritaDto,
  AggiornaPrioritaSchema,
  AggiornaStatoDto,
  AggiornaStatoSchema,
  AssegnaProblemaDto,
  AssegnaProblemaSchema,
  CreaProblemaDto,
  CreaProblemaSchema,
} from "../dto/ProblemaDto";
import { mapErrorToHttp } from "../errors/errorMapper";

export class ProblemaController {
  constructor(private problemiService: ProblemaService) {}

  /**
   * GET /case/:idCasa/problemi
   */
  getAllProblemi = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const problemi = await this.problemiService.getAllProblemi(
        request.params.idCasa,
      );
      return reply.status(200).send(problemi);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case/:idCasa/problemi/non-risolti
   */
  getProblemiNonRisolti = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const problemi = await this.problemiService.getProblemiIrrisolti(
        request.params.idCasa,
      );
      return reply.status(200).send(problemi);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case/:idCasa/problemi/:idProblema
   */
  getProblema = async (
    request: FastifyRequest<{ Params: ProblemaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const problema = await this.problemiService.getProblema(
        request.params.idCasa,
        request.params.idProblema,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * POST /case/:idCasa/problemi
   */
  segnalaProblema = async (
    request: FastifyRequest<{ Params: CasaParams; Body: CreaProblemaDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = CreaProblemaSchema.parse(request.body);
      const problema = await this.problemiService.segnalaProblema(
        request.params.idCasa,
        dto,
        request.user.idUtente,
      );
      return reply.status(201).send(problema);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * DELETE /case/:idCasa/problemi/:idProblema
   */
  eliminaProblema = async (
    request: FastifyRequest<{ Params: ProblemaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      await this.problemiService.eliminaProblema(
        request.params.idCasa,
        request.params.idProblema,
      );
      return reply.status(204).send();
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * PUT /case/:idCasa/problemi/:idProblema/autoassegna
   */
  autoassegnaProblema = async (
    request: FastifyRequest<{ Params: ProblemaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const problema = await this.problemiService.autoassegnaProblema(
        request.params.idCasa,
        request.params.idProblema,
        request.user.idUtente,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * PUT /case/:idCasa/problemi/:idProblema/assegna
   */
  assegnaProblema = async (
    request: FastifyRequest<{
      Params: ProblemaParams;
      Body: AssegnaProblemaDto;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = AssegnaProblemaSchema.parse(request.body);
      const problema = await this.problemiService.assegnaProblema(
        request.params.idCasa,
        request.params.idProblema,
        dto,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * PATCH /case/:idCasa/problemi/:idProblema/stato
   */
  aggiornaStato = async (
    request: FastifyRequest<{ Params: ProblemaParams; Body: AggiornaStatoDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = AggiornaStatoSchema.parse(request.body);
      const problema = await this.problemiService.aggiornaStato(
        request.params.idCasa,
        request.params.idProblema,
        dto,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * PATCH /case/:idCasa/problemi/:idProblema/priorita
   */
  aggiornaPriorita = async (
    request: FastifyRequest<{
      Params: ProblemaParams;
      Body: AggiornaPrioritaDto;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = AggiornaPrioritaSchema.parse(request.body);
      const problema = await this.problemiService.aggiornaPriorita(
        request.params.idCasa,
        request.params.idProblema,
        dto,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };
}
