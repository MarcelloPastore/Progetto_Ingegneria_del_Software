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
  cadenzaGiorni: number;
  rotazioneAttiva: boolean;
  assegnatarioCorrente: string;
  ordineRotazione: string[];
  indiceRotazioneCorrente: number;
};

type TurnoUpdateData = {
  task?: string;
  cadenzaGiorni?: number;
  rotazioneAttiva?: boolean;
  ordineRotazione?: string[];
  assegnatarioCorrente?: string;
  dataUltimaPulizia?: Date;
  indiceRotazioneCorrente?: number;
};

export class TurnoRepository {
  async createTurno(data: TurnoCreateData): Promise<TurnoConAssegnatario> {
    return prisma.turno.create({
      data,
      include: INCLUDE_ASSEGNATARIO,
    });
  }

  async updateTurno(
    idTurno: string,
    data: TurnoUpdateData,
  ): Promise<TurnoConAssegnatario> {
    return prisma.turno.update({
      where: { id: idTurno },
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

  async deleteTurno(idCasa: string, idTurno: string): Promise<void> {
    await prisma.turno.delete({ where: { id: idTurno, idCasa } });
  }
}
