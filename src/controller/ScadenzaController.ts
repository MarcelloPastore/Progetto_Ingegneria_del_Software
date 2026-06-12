import { FastifyRequest, FastifyReply } from "fastify";
import { CasaParams, ScadenzaParams } from "../types/params";
import {
  CreaScadenzaDto,
  ModificaScadenzaDto,
  AggiornaRicorrenzaDto,
} from "../dto/ScadenzaDto";
import { ScadenzaService } from "../service/ScadenzaService";
import { sendErrorReply } from "../utils/errorReply";

export class ScadenzaController {
  constructor(private readonly scadenzeService: ScadenzaService) {}

  private handleFailure(reply: FastifyReply, error: unknown) {
    return sendErrorReply(reply, error);
  }

  /**
   * GET /case/:idCasa/scadenze
   */
  getAllScadenze = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const scadenze = await this.scadenzeService.getAllScadenze(
        request.params.idCasa,
      );
      return reply.status(200).send(scadenze);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/scadenze/:idScadenza
   */
  getScadenza = async (
    request: FastifyRequest<{ Params: ScadenzaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const scadenza = await this.scadenzeService.getScadenza(
        request.params.idCasa,
        request.params.idScadenza,
      );
      return reply.status(200).send(scadenza);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * POST /case/:idCasa/scadenze
   */
  creaScadenza = async (
    request: FastifyRequest<{ Params: CasaParams; Body: unknown }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = CreaScadenzaDto.parse(request.body);
      const scadenza = await this.scadenzeService.creaScadenza(
        request.params.idCasa,
        dto,
      );
      return reply.status(201).send(scadenza);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PUT /case/:idCasa/scadenze/:idScadenza
   */
  modificaScadenza = async (
    request: FastifyRequest<{ Params: ScadenzaParams; Body: unknown }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaScadenzaDto.parse(request.body);
      const scadenza = await this.scadenzeService.modificaScadenza(
        request.params.idCasa,
        request.params.idScadenza,
        dto,
      );
      return reply.status(200).send(scadenza);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * DELETE /case/:idCasa/scadenze/:idScadenza
   */
  eliminaScadenza = async (
    request: FastifyRequest<{ Params: ScadenzaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      await this.scadenzeService.eliminaScadenza(
        request.params.idCasa,
        request.params.idScadenza,
      );
      return reply.status(204).send();
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PATCH /case/:idCasa/scadenze/:idScadenza/ricorrenza
   */
  aggiornaRicorrenza = async (
    request: FastifyRequest<{ Params: ScadenzaParams; Body: unknown }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = AggiornaRicorrenzaDto.parse(request.body);
      const scadenza = await this.scadenzeService.aggiornaRicorrenza(
        request.params.idCasa,
        request.params.idScadenza,
        dto,
      );
      return reply.status(200).send(scadenza);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };
}
