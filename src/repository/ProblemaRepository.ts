import { prisma } from "../config/db";
import { Priorita, Stato } from "@prisma/client";

export const INCLUDE_PROBLEMA_REL = {
  segnalataDaRel: {
    select: { id: true, username: true },
  },
  assegnatarioRel: {
    select: { id: true, username: true },
  },
  storicoStato: {
    include: { utenteRel: { select: { id: true, username: true } } },
    orderBy: { data: "asc" as const },
  },
} as const;

const _problemaQuery = () =>
  prisma.problema.findFirst({ include: INCLUDE_PROBLEMA_REL });

export type ProblemaConRelazioni = NonNullable<
  Awaited<ReturnType<typeof _problemaQuery>>
>;

type ProblemaCreateData = {
  idCasa: string;
  nome: string;
  descrizione: string;
  segnalataDa: string;
  priorita?: Priorita;
};

type ProblemaUpdateData = {
  nome?: string;
  descrizione?: string;
  priorita?: Priorita;
  stato?: Stato;
  assegnatario?: string | null;
  dataRisoluzione?: Date | null;
};

export class ProblemaRepository {
  async createProblema(
    data: ProblemaCreateData,
  ): Promise<ProblemaConRelazioni> {
    return prisma.problema.create({
      data: {
        ...data,
        storicoStato: {
          create: { stato: Stato.Segnalato, utente: data.segnalataDa },
        },
      },
      include: INCLUDE_PROBLEMA_REL,
    });
  }

  async updateProblema(
    idProblema: string,
    data: ProblemaUpdateData,
  ): Promise<ProblemaConRelazioni> {
    return prisma.problema.update({
      where: { id: idProblema },
      data,
      include: INCLUDE_PROBLEMA_REL,
    });
  }

  async findProblemiByCasa(idCasa: string): Promise<ProblemaConRelazioni[]> {
    return prisma.problema.findMany({
      where: { idCasa },
      include: INCLUDE_PROBLEMA_REL,
    });
  }

  async findProblemiNonRisolti(
    idCasa: string,
  ): Promise<ProblemaConRelazioni[]> {
    return prisma.problema.findMany({
      where: { idCasa, stato: { not: Stato.Risolto } },
      include: INCLUDE_PROBLEMA_REL,
    });
  }

  async findProblemaByIdOrThrow(
    idCasa: string,
    idProblema: string,
  ): Promise<ProblemaConRelazioni> {
    return prisma.problema.findFirstOrThrow({
      where: { id: idProblema, idCasa },
      include: INCLUDE_PROBLEMA_REL,
    });
  }

  async deleteProblema(idCasa: string, idProblema: string): Promise<void> {
    await prisma.storico.deleteMany({ where: { idProblema } });
    await prisma.problema.delete({ where: { id: idProblema, idCasa } });
  }

  async createStorico(
    idProblema: string,
    stato: Stato,
    idUtente: string,
  ): Promise<void> {
    await prisma.storico.create({
      data: { idProblema, stato, utente: idUtente },
    });
  }
}
