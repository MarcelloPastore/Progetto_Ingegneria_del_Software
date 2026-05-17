import { prisma } from "../config/db";

export const INCLUDE_ASSEGNATARIO = {
  assegnatarioCorrenteRel: {
    select: { id: true, username: true },
  },
} as const;

const _turnoQuery = () =>
  prisma.turno.findFirst({ include: INCLUDE_ASSEGNATARIO });

export type TurnoConAssegnatario = NonNullable<
  Awaited<ReturnType<typeof _turnoQuery>>
>;

type TurnoCreateData = {
  idCasa: string;
  task: string;
  rotazioneAttiva: boolean;
  assegnatarioCorrente: string;
  ordineRotazione: string[];
  indiceRotazioneCorrente: number;
};

export class TurnoRepository {
  async createTurno(data: TurnoCreateData): Promise<TurnoConAssegnatario> {
    return prisma.turno.create({
      data,
      include: INCLUDE_ASSEGNATARIO,
    });
  }

  async findTurniByCasa(idCasa: string): Promise<TurnoConAssegnatario[]> {
    return prisma.turno.findMany({
      where: { idCasa },
      include: INCLUDE_ASSEGNATARIO,
    });
  }

  async findTurnoByIdOrThrow(
    idCasa: string,
    idTurno: string,
  ): Promise<TurnoConAssegnatario> {
    return prisma.turno.findFirstOrThrow({
      where: { id: idTurno, idCasa },
      include: INCLUDE_ASSEGNATARIO,
    });
  }
}
