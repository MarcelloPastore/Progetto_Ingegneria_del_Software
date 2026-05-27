import { FastifyReply, FastifyRequest } from "fastify";

import {
  AggiungiInquilinoDto,
  AggiungiInquilinoSchema,
  CreaCasaDto,
  CreaCasaSchema,
  ModificaRuoloInquilinoDto,
  ModificaRuoloInquilinoSchema,
} from "../dto/CasaDto";
import { CasaService } from "../service/CasaService";
import { CasaParams, InquilinoParams } from "../types/params";
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
      const caseUtente = await this.casaService.getCase(request.user.idUtente);
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

  /**
   * DELETE /case/:idCasa
   */
  eliminaCasa = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      await this.casaService.eliminaCasa(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(204).send();
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case/:idCasa/inquilini
   */
  getInquilini = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const inquilini = await this.casaService.getInquilini(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send({ inquilini });
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case/:idCasa/inquilini/:idInquilino
   */
  getInquilino = async (
    request: FastifyRequest<{ Params: InquilinoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const inquilino = await this.casaService.getInquilino(
        request.params.idCasa,
        request.params.idInquilino,
        request.user.idUtente,
      );
      return reply.status(200).send(inquilino);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * POST /case/:idCasa/inquilini
   */
  aggiungiInquilino = async (
    request: FastifyRequest<{
      Params: CasaParams;
      Body: AggiungiInquilinoDto;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = AggiungiInquilinoSchema.parse(request.body);
      const inquilino = await this.casaService.aggiungiInquilino(
        request.params.idCasa,
        dto,
        request.user.idUtente,
      );
      return reply.status(201).send(inquilino);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * DELETE /case/:idCasa/inquilini/:idInquilino
   */
  rimuoviInquilino = async (
    request: FastifyRequest<{ Params: InquilinoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      await this.casaService.rimuoviInquilino(
        request.params.idCasa,
        request.params.idInquilino,
        request.user.idUtente,
      );
      return reply.status(204).send();
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * PUT /case/:idCasa/inquilini/:idInquilino/ruolo
   */
  modificaRuoloInquilino = async (
    request: FastifyRequest<{
      Params: InquilinoParams;
      Body: ModificaRuoloInquilinoDto;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaRuoloInquilinoSchema.parse(request.body);
      const inquilino = await this.casaService.modificaRuoloInquilino(
        request.params.idCasa,
        request.params.idInquilino,
        dto,
        request.user.idUtente,
      );
      return reply.status(200).send(inquilino);
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };

  /**
   * GET /case/:idCasa/invite-link
   */
  getInviteLink = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const casa = await this.casaService.getCasa(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send({ inviteLink: casa.inviteLink });
    } catch (error) {
      const mapped = mapErrorToHttp(error);
      return reply.status(mapped.statusCode).send({ message: mapped.message });
    }
  };
}
