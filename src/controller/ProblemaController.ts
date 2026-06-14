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
  ModificaProblemaDto,
  ModificaProblemaSchema,
} from "../dto/ProblemaDto";
import { sendErrorReply } from "../utils/errorReply";

export class ProblemaController {
  constructor(private readonly problemiService: ProblemaService) {}

  private handleFailure(reply: FastifyReply, error: unknown) {
    return sendErrorReply(reply, error);
  }

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
      return this.handleFailure(reply, error);
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
      return this.handleFailure(reply, error);
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
      return this.handleFailure(reply, error);
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
      return this.handleFailure(reply, error);
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
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PUT /case/:idCasa/problemi/:idProblema
   */
  modificaProblema = async (
    request: FastifyRequest<{
      Params: ProblemaParams;
      Body: ModificaProblemaDto;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaProblemaSchema.parse(request.body);
      const problema = await this.problemiService.modificaProblema(
        request.params.idCasa,
        request.params.idProblema,
        dto,
        request.user.idUtente,
        request.user.ruoloCasa,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PUT /case/:idCasa/problemi/:idProblema/rinuncia
   */
  rinunciaProblema = async (
    request: FastifyRequest<{ Params: ProblemaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const problema = await this.problemiService.rinunciaProblema(
        request.params.idCasa,
        request.params.idProblema,
        request.user.idUtente,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      return this.handleFailure(reply, error);
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
      return this.handleFailure(reply, error);
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
        request.user.idUtente,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      return this.handleFailure(reply, error);
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
        request.user.idUtente,
      );
      return reply.status(200).send(problema);
    } catch (error) {
      return this.handleFailure(reply, error);
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
      return this.handleFailure(reply, error);
    }
  };
}
