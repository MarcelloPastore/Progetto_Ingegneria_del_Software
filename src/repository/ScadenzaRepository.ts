import { prisma } from "../config/db";

export const SELECT_SCADENZA_BASE = {
  id: true,
  nome: true,
  descrizione: true,
  dataScadenza: true,
  isRicorrente: true,
  cadenzaGiorni: true,
  idCasa: true,
  dataCreazione: true,
  idCreatore: true,
} as const;

const _scadenzaQuery = () =>
  prisma.scadenza.findFirst({ select: SELECT_SCADENZA_BASE });

export type ScadenzaBase = NonNullable<
  Awaited<ReturnType<typeof _scadenzaQuery>>
>;

type ScadenzaCreateData = {
  idCasa: string;
  nome: string;
  descrizione: string;
  dataScadenza: Date;
  isRicorrente: boolean;
  cadenzaGiorni?: number | null;
  idCreatore?: string | null;
};

type ScadenzaUpdateData = {
  nome?: string;
  descrizione?: string;
  dataScadenza?: Date;
  isRicorrente?: boolean;
  cadenzaGiorni?: number | null;
};

export class ScadenzaRepository {
  async createScadenza(data: ScadenzaCreateData): Promise<ScadenzaBase> {
    return prisma.scadenza.create({
      data: {
        idCasa: data.idCasa,
        nome: data.nome,
        descrizione: data.descrizione,
        dataScadenza: data.dataScadenza,
        isRicorrente: data.isRicorrente,
        cadenzaGiorni: data.cadenzaGiorni ?? undefined,
        idCreatore: data.idCreatore ?? undefined,
      },
      select: SELECT_SCADENZA_BASE,
    });
  }

  async updateScadenza(
    idScadenza: string,
    data: ScadenzaUpdateData,
  ): Promise<ScadenzaBase> {
    return prisma.scadenza.update({
      where: { id: idScadenza },
      data: {
        ...(data.nome !== undefined && { nome: data.nome }),
        ...(data.descrizione !== undefined && {
          descrizione: data.descrizione,
        }),
        ...(data.dataScadenza !== undefined && {
          dataScadenza: data.dataScadenza,
        }),
        ...(data.isRicorrente !== undefined && {
          isRicorrente: data.isRicorrente,
        }),
        ...(data.cadenzaGiorni !== undefined && {
          cadenzaGiorni: data.cadenzaGiorni ?? undefined,
        }),
      },
      select: SELECT_SCADENZA_BASE,
    });
  }

  async findScadenzeByCasa(idCasa: string): Promise<ScadenzaBase[]> {
    return prisma.scadenza.findMany({
      where: { idCasa },
      select: SELECT_SCADENZA_BASE,
    });
  }

  async findScadenzaByIdOrThrow(
    idCasa: string,
    idScadenza: string,
  ): Promise<ScadenzaBase> {
    return prisma.scadenza.findFirstOrThrow({
      where: { id: idScadenza, idCasa },
      select: SELECT_SCADENZA_BASE,
    });
  }

  async deleteScadenza(idCasa: string, idScadenza: string): Promise<void> {
    await prisma.scadenza.delete({ where: { id: idScadenza, idCasa } });
  }
}
