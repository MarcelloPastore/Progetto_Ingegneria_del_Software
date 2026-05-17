import { FastifyRequest, FastifyReply } from "fastify";
import {
  AssegnaTurnoDto,
  CreaTurnoDto,
  ModificaTurnoDto,
  CreaTurnoSchema,
  ModificaTurnoSchema,
  AssegnaTurnoSchema,
} from "../dto/TurnoDto";
import { TurnoService } from "../service/TurnoService";
import { CasaParams, TurnoParams } from "../types/params";

export class TurnoController {
  constructor(private turniService: TurnoService) {}

  //TODO: Implementare verifiche dei permessi HomaAdmin
  //TODO: Implementare error code differenziati per API

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
      return reply.status(500).send({ message: "Errore interno del server" });
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
      return reply.status(500).send({ message: "Errore interno del server" });
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
      );
      return reply.status(201).send(result);
    } catch (error) {
      return reply.status(400).send({ message: "Dati non validi" });
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
      return reply.status(404).send({ message: "Turno non trovato" });
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
      );
      return reply.status(200).send(result);
    } catch (error) {
      return reply.status(400).send({ message: "Dati non validi" });
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
      );
      return reply.status(204).send();
    } catch (error) {
      return reply.status(500).send({ message: "Errore interno del server" });
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
      return reply
        .status(400)
        .send({ message: "Dati non validi" });
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
      return reply.status(500).send({ message: "Errore interno del server" });
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
      );
      return reply.status(200).send(result);
    } catch (error) {
      return reply.status(500).send({ message: "Errore interno del server" });
    }
  };
}
