import { FastifyRequest, FastifyReply } from "fastify";
import {
  AssegnaTurnoDto,
  CreaTurnoDto,
  ModificaTurnoDto,
  CreaTurnoSchema,
  ModificaTurnoSchema,
  AssegnaTurnoSchema,
  SaluteCasaDto,
} from "../dto/TurnoDto";
import { TurnoService } from "../service/TurnoService";
import { CasaParams, TurnoParams } from "../types/params";
import { mapErrorToHttp } from "../errors/errorMapper";

export class TurnoController {
  constructor(private readonly turniService: TurnoService) {}

  private handleFailure(reply: FastifyReply, error: unknown) {
    const mapped = mapErrorToHttp(error);
    return reply.status(mapped.statusCode).send({ message: mapped.message });
  }

  /**
   * GET /case/:idCasa/turni
   */
  getAllTurni = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const turni = await this.turniService.getAllTurni(request.params.idCasa);
      return reply.status(200).send(turni);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/turni/oggi
   */
  getTurniOdierni = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const turni = await this.turniService.getTurniOdierni(
        request.params.idCasa,
      );
      return reply.status(200).send(turni);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/turni/salute-casa
   */
  getGiorniDallUltimaPulizia = async (
    request: FastifyRequest<{ Params: CasaParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const result: SaluteCasaDto[] =
        await this.turniService.getGiorniDallUltimaPulizia(
          request.params.idCasa,
        );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * POST /case/:idCasa/turni
   */
  creaTurno = async (
    request: FastifyRequest<{ Params: CasaParams; Body: CreaTurnoDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = CreaTurnoSchema.parse(request.body);
      const result = await this.turniService.creaTurno(
        request.params.idCasa,
        dto,
        request.user.idUtente,
      );
      return reply.status(201).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * GET /case/:idCasa/turni/:idTurno
   */
  getTurno = async (
    request: FastifyRequest<{ Params: TurnoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const result = await this.turniService.getTurno(
        request.params.idCasa,
        request.params.idTurno,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PATCH /case/:idCasa/turni/:idTurno
   */
  modificaTurno = async (
    request: FastifyRequest<{ Params: TurnoParams; Body: ModificaTurnoDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = ModificaTurnoSchema.parse(request.body);
      const result = await this.turniService.modificaTurno(
        request.params.idCasa,
        request.params.idTurno,
        dto,
        request.user.idUtente,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * DELETE /case/:idCasa/turni/:idTurno
   */
  eliminaTurno = async (
    request: FastifyRequest<{ Params: TurnoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      await this.turniService.eliminaTurno(
        request.params.idCasa,
        request.params.idTurno,
        request.user.idUtente,
      );
      return reply.status(204).send();
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PUT /case/:idCasa/turni/:idTurno/autoassegna
   */
  autoassegnaTurno = async (
    request: FastifyRequest<{ Params: TurnoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const result = await this.turniService.autoassegnaTurno(
        request.params.idCasa,
        request.params.idTurno,
        request.user.idUtente,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PUT /case/:idCasa/turni/:idTurno/assegna
   */
  assegnaTurno = async (
    request: FastifyRequest<{ Params: TurnoParams; Body: AssegnaTurnoDto }>,
    reply: FastifyReply,
  ) => {
    try {
      const dto = AssegnaTurnoSchema.parse(request.body);
      const result = await this.turniService.assegnaTurno(
        request.params.idCasa,
        request.params.idTurno,
        dto,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * PATCH /case/:idCasa/turni/:idTurno/rotazione
   */
  toggleRotazioneTurni = async (
    request: FastifyRequest<{ Params: TurnoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const result = await this.turniService.toggleRotazioneTurni(
        request.params.idCasa,
        request.params.idTurno,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };

  /**
   * POST /case/:idCasa/turni/:idTurno/completa
   */
  completaTurno = async (
    request: FastifyRequest<{ Params: TurnoParams }>,
    reply: FastifyReply,
  ) => {
    try {
      const result = await this.turniService.completaTurno(
        request.params.idCasa,
        request.params.idTurno,
        request.user.idUtente,
      );
      return reply.status(200).send(result);
    } catch (error) {
      return this.handleFailure(reply, error);
    }
  };
}
