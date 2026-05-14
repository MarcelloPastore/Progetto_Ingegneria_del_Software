import { FastifyRequest, FastifyReply } from "fastify";
import {
  AssegnaTurnoDto,
  CreaTurnoDto,
  ModificaTurnoDto,
  TurnoResponseDto,
  CreaTurnoSchema,
  ModificaTurnoSchema,
  AssegnaTurnoSchema,
} from "../dto/TurnoDto";
import { TurniService } from "../service/TurniService";
import { CasaPayload, TurnoPayload } from "../types/params";

export class TurnoController {
  getAllTurni = async (
    request: FastifyRequest<{ Params: CasaPayload }>,
    reply: FastifyReply,
  ) => {
    const { idCasa } = request.params;
    const user = request.user as JwtCustomPayload;

    // TODO: implementare
    const responseDto: TurnoResponseDto[] = [];
    return reply.status(200).send(responseDto);
  };

  creaTurno = async (
    request: FastifyRequest<{ Params: CasaPayload; Body: CreaTurnoDto }>,
    reply: FastifyReply,
  ) => {
    const { idCasa } = request.params;
    const body = CreaTurnoSchema.safeParse(request.body);
    const user = request.user as JwtCustomPayload;

    TurniService.creaTurno(idCasa, body.data);

    // TODO: implementare
    return reply.status(201).send({ message: "Turno creato" });
  };

  getTurno = async (
    request: FastifyRequest<{ Params: TurnoPayload }>,
    reply: FastifyReply,
  ) => {
    const { idCasa, idTurno } = request.params;
    const user = request.user as JwtCustomPayload;

    // TODO: implementare
    const responseDto = {} as TurnoResponseDto;
    return reply.status(200).send(responseDto);
  };

  modificaTurno = async (
    request: FastifyRequest<{ Params: TurnoPayload; Body: ModificaTurnoDto }>,
    reply: FastifyReply,
  ) => {
    const { idCasa, idTurno } = request.params;
    const body = ModificaTurnoSchema.safeParse(request.body);
    const user = request.user as JwtCustomPayload;

    // TODO: implementare
    return reply.status(200).send({ message: "Turno modificato" });
  };

  eliminaTurno = async (
    request: FastifyRequest<{ Params: TurnoPayload }>,
    reply: FastifyReply,
  ) => {
    const { idCasa, idTurno } = request.params;
    const user = request.user as JwtCustomPayload;

    TurniService.eliminaTurno(idCasa, idTurno);
    // TODO: implementare
    return reply.status(204).send();
  };

  assegnaTurno = async (
    request: FastifyRequest<{ Params: TurnoPayload; Body: AssegnaTurnoDto }>,
    reply: FastifyReply,
  ) => {
    const { idCasa, idTurno } = request.params;
    const body = AssegnaTurnoSchema.safeParse(request.body);
    const user = request.user as JwtCustomPayload;

    // TODO: implementare
    return reply.status(200).send({ message: "Turno assegnato" });
  };

  toggleRotazioneTurni = async (
    request: FastifyRequest<{ Params: TurnoPayload }>,
    reply: FastifyReply,
  ) => {
    const { idCasa, idTurno } = request.params;
    const user = request.user as JwtCustomPayload;

    // TODO: implementare
    return reply.status(200).send({ message: "Rotazione modificabile" });
  };

  completaTurno = async (
    request: FastifyRequest<{ Params: TurnoPayload }>,
    reply: FastifyReply,
  ) => {
    const { idCasa, idTurno } = request.params;
    const user = request.user as JwtCustomPayload;

    // TODO: implementare
    return reply.status(200).send({ message: "Turno completato" });
  };
}
