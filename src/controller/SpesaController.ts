import { FastifyRequest, FastifyReply } from "fastify";
import {
  CasaParams,
  SpesaParams,
  QuotaParams,
  InquilinoParams,
} from "../types/params";
import { SpesaService } from "../service/SpesaService";
import {
  CreaSpesaDto,
  CreaSpesaSchema,
  ModificaSpesaDto,
  ModificaSpesaSchema,
  PareggiaContiDto,
  PareggiaContiSchema,
} from "../dto/SpesaDto";
import { mapErrorToHttp } from "../errors/errorMapper";

export class SpesaController {
  constructor(private readonly speseService: SpesaService) {}

  private handleFailure(reply: FastifyReply, error: unknown) {
    const mapped = mapErrorToHttp(error);
    return reply.status(mapped.statusCode).send({ message: mapped.message });
  }

  /**
   * GET /case/:idCasa/spese
   */
  getAllSpese = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const spese = await this.speseService.getAllSpese(request.params.idCasa);
      return reply.status(200).send(spese);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/spese/:idSpesa
   */
  getSpesa = async (
    request: FastifyRequest<{ Params: SpesaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const spesa = await this.speseService.getSpesa(
        request.params.idCasa,
        request.params.idSpesa,
      );
      return reply.status(200).send(spesa);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/saldo
   */
  getSaldo = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const saldoTot = await this.speseService.getSaldo(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send(saldoTot);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/credito
   */
  getCreditoTot = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const creditoTot = await this.speseService.getCredito(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send(creditoTot);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/debito
   */
  getDebitoTot = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const debitoTot = await this.speseService.getDebito(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send(debitoTot);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * POST /case/:idCasa/spese
   */
  addSpesa = async (
    request: FastifyRequest<{ Params: CasaParams; Body: CreaSpesaDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = CreaSpesaSchema.parse(request.body);
      const spesa = await this.speseService.addSpesa(
        request.params.idCasa,
        dto,
        request.user.idUtente,
      );
      return reply.status(201).send(spesa);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PUT /case/:idCasa/spese/:idSpesa
   */
  updateSpesa = async (
    request: FastifyRequest<{ Params: SpesaParams; Body: ModificaSpesaDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaSpesaSchema.parse(request.body);
      const spesa = await this.speseService.updateSpesa(
        request.params.idCasa,
        request.params.idSpesa,
        dto,
        request.user.idUtente,
      );
      return reply.status(200).send(spesa);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * DELETE /case/:idCasa/spese/:idSpesa
   */
  deleteSpesa = async (
    request: FastifyRequest<{ Params: SpesaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      await this.speseService.deleteSpesa(
        request.params.idCasa,
        request.params.idSpesa,
        request.user.idUtente,
      );
      return reply.status(204).send();
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/spese/:idSpesa/quote
   */
  getDivisioneSpese = async (
    request: FastifyRequest<{ Params: SpesaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const quote = await this.speseService.getDivisioneSpese(
        request.params.idCasa,
        request.params.idSpesa,
      );
      return reply.status(200).send(quote);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/spese/:idSpesa/quote/:idQuota
   */
  getQuota = async (
    request: FastifyRequest<{ Params: QuotaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const quota = await this.speseService.getQuota(
        request.params.idCasa,
        request.params.idSpesa,
        request.params.idQuota,
        request.user.idUtente,
      );
      return reply.status(200).send(quota);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * POST /case/:idCasa/spese/:idSpesa/quote/:idQuota/paga
   */
  pagaQuota = async (
    request: FastifyRequest<{ Params: QuotaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const quote = await this.speseService.pagaQuota(
        request.params.idCasa,
        request.params.idSpesa,
        request.params.idQuota,
        request.user.idUtente,
      );
      return reply.status(200).send(quote);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * POST /case/:idCasa/spese/pareggia
   */
  pareggiaConti = async (
    request: FastifyRequest<{ Params: CasaParams; Body: PareggiaContiDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = PareggiaContiSchema.parse(request.body);
      await this.speseService.pareggiaConti(
        request.params.idCasa,
        request.user.idUtente,
        dto,
      );
      return reply.status(204).send();
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/credito/:idInquilino
   */
  getCreditoVersoUtente = async (
    request: FastifyRequest<{ Params: InquilinoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const credito = await this.speseService.getCreditoVersoUtente(
        request.params.idCasa,
        request.params.idInquilino,
        request.user.idUtente,
      );
      return reply.status(200).send(credito);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/debito/:idInquilino
   */
  getDebitoVersoUtente = async (
    request: FastifyRequest<{ Params: InquilinoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const debito = await this.speseService.getDebitoVersoUtente(
        request.params.idCasa,
        request.params.idInquilino,
        request.user.idUtente,
      );
      return reply.status(200).send(debito);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };
}
