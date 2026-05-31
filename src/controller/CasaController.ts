import { FastifyReply, FastifyRequest } from "fastify";
import {
  AggiungiInquilinoDto,
  AggiungiInquilinoSchema,
  CreaCasaDto,
  CreaCasaSchema, ModificaCasaDto, ModificaCasaSchema,
  ModificaRuoloDto,
  ModificaRuoloSchema,
} from "../dto/CasaDto";
import { CasaService } from "../service/CasaService";
import { CasaParams, InquilinoParams } from "../types/params";
import { mapErrorToHttp } from "../errors/errorMapper";

export class CasaController {
  constructor(private readonly casaService: CasaService) {}

  private handleFailure(reply: FastifyReply, error: unknown) {
    const mapped = mapErrorToHttp(error);
    return reply.status(mapped.statusCode).send({ message: mapped.message });
  }

  creaCasa = async (
    request: FastifyRequest<{ Body: CreaCasaDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = CreaCasaSchema.parse(request.body);
      const casa = await this.casaService.creaCasa(dto, request.user.idUtente);
      return reply.status(201).send(casa);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  getCase = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const caseUtente = await this.casaService.getCase(request.user.idUtente);
      return reply.status(200).send(caseUtente);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

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
      return this.handleFailure(reply, error);
    }
  };

  modificaCasa = async (
    request: FastifyRequest<{ Params: CasaParams, Body: ModificaCasaDto }>,
    reply: FastifyReply,
  )=> {
    try {
      const dto = ModificaCasaSchema.parse(request.body);
      await this.casaService.modificaCasa(
        request.params.idCasa,
        request.user.idUtente,
        dto,
      );
      return reply.status(204).send();
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

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
      return this.handleFailure(reply, error);
    }
  };

  getAllInquilini = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const inquilini = await this.casaService.getAllInquilini(
        request.params.idCasa,
        request.user.idUtente,
      );
      return reply.status(200).send(inquilini);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

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
      return this.handleFailure(reply, error);
    }
  };

  aggiungiInquilino = async (
    request: FastifyRequest<{ Params: CasaParams; Body: AggiungiInquilinoDto }>,
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
      return this.handleFailure(reply, error);
    }
  };

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
      return this.handleFailure(reply, error);
    }
  };

  modificaRuoloInquilino = async (
    request: FastifyRequest<{
      Params: InquilinoParams;
      Body: ModificaRuoloDto;
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaRuoloSchema.parse(request.body);
      const inquilino = await this.casaService.modificaRuolo(
        request.params.idCasa,
        request.params.idInquilino,
        dto,
        request.user.idUtente,
      );
      return reply.status(200).send(inquilino);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  generaLink = async (
    request: FastifyRequest<{
      Params: CasaParams;
      Querystring?: { rigenera?: string | boolean };
    }>,
    reply: FastifyReply,
  ) => {
    try {
      const rigenera =
        request.query?.rigenera === true ||
        request.query?.rigenera === "true" ||
        request.query?.rigenera === "1";
      const link = await this.casaService.generaLink(
        request.params.idCasa,
        request.user.idUtente,
        rigenera,
      );
      return reply.status(200).send(link);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };
}
