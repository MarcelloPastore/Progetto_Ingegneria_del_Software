import type { Prisma } from "@prisma/client";
import { prisma } from "../config/db";

export const INCLUDE_INQUILINO = {
  select: { id: true, username: true },
} as const;

export const INCLUDE_SPESA_BASE = {
  ownerRel: INCLUDE_INQUILINO,
  anticipataDaRel: INCLUDE_INQUILINO,
  partecipantiRel: INCLUDE_INQUILINO,
  scadenzaRel: {
    select: {
      dataScadenza: true,
      isRicorrente: true,
      cadenzaGiorni: true,
    },
  },
  quote: {
    select: {
      id: true,
      quota: true,
      dataPagamento: true,
      idUtente: true,
      utenteRel: INCLUDE_INQUILINO,
    },
  },
} as const;

export const INCLUDE_QUOTA_WITH_SPESA = {
  utenteRel: INCLUDE_INQUILINO,
  spesaRel: {
    select: {
      id: true,
      descrizione: true,
      importo: true,
      anticipataDa: true,
      anticipataDaRel: INCLUDE_INQUILINO,
    },
  },
} as const;

const _spesaQuery = () =>
  prisma.spesa.findFirst({ include: INCLUDE_SPESA_BASE });

const _quotaQuery = () =>
  prisma.quotaSpesa.findFirst({ include: INCLUDE_QUOTA_WITH_SPESA });

export type SpesaConRelazioni = NonNullable<
  Awaited<ReturnType<typeof _spesaQuery>>
>;

export type QuotaConRelazioni = NonNullable<
  Awaited<ReturnType<typeof _quotaQuery>>
>;

type SpesaCreateData = {
  idCasa: string;
  descrizione: string;
  importo: number;
  owner: string;
  anticipataDa?: string | null;
  partecipanti: string[];
  scadenza?: {
    nome: string;
    descrizione: string;
    dataScadenza: Date;
    isRicorrente: boolean;
    cadenzaGiorni?: number | null;
  };
  quote: Array<{
    idUtente: string;
    quota: number;
    dataPagamento?: Date | null;
  }>;
};

type SpesaUpdateData = {
  descrizione?: string;
  importo?: number;
  anticipataDa?: string | null;
  partecipanti?: string[];
};

type ScadenzaUpsertData = {
  nome: string;
  descrizione: string;
  dataScadenza: Date;
  isRicorrente: boolean;
  cadenzaGiorni?: number | null;
};

export class SpesaRepository {
  async createSpesa(data: SpesaCreateData): Promise<SpesaConRelazioni> {
    const createData: Prisma.SpesaCreateInput = {
      descrizione: data.descrizione,
      importo: data.importo,
      casaRel: { connect: { id: data.idCasa } },
      ownerRel: { connect: { id: data.owner } },
      ...(data.anticipataDa
        ? { anticipataDaRel: { connect: { id: data.anticipataDa } } }
        : {}),
      partecipantiRel: {
        connect: data.partecipanti.map((id) => ({ id })),
      },
      ...(data.scadenza
        ? {
            scadenzaRel: {
              create: {
                nome: data.scadenza.nome,
                descrizione: data.scadenza.descrizione,
                dataScadenza: data.scadenza.dataScadenza,
                isRicorrente: data.scadenza.isRicorrente,
                cadenzaGiorni: data.scadenza.cadenzaGiorni ?? undefined,
                casaRel: { connect: { id: data.idCasa } },
              },
            },
          }
        : {}),
      quote: {
        create: data.quote.map((q) => ({
          quota: q.quota,
          ...(q.dataPagamento ? { dataPagamento: q.dataPagamento } : {}),
          utenteRel: { connect: { id: q.idUtente } },
          casaRel: { connect: { id: data.idCasa } },
        })),
      },
    };

    return prisma.spesa.create({
      data: createData,
      include: INCLUDE_SPESA_BASE,
    });
  }

  async updateSpesa(
    idCasa: string,
    idSpesa: string,
    data: SpesaUpdateData,
    quote?: SpesaCreateData["quote"],
    scadenza?: ScadenzaUpsertData,
  ): Promise<SpesaConRelazioni> {
    return prisma.$transaction(async (tx) => {
      const updateData: Prisma.SpesaUpdateInput = {
        ...(data.descrizione !== undefined && {
          descrizione: data.descrizione,
        }),
        ...(data.importo !== undefined && { importo: data.importo }),
        ...(data.partecipanti
          ? {
              partecipantiRel: {
                set: data.partecipanti.map((id) => ({ id })),
              },
            }
          : {}),
        ...(scadenza
          ? {
              scadenzaRel: {
                upsert: {
                  create: {
                    nome: scadenza.nome,
                    descrizione: scadenza.descrizione,
                    dataScadenza: scadenza.dataScadenza,
                    isRicorrente: scadenza.isRicorrente,
                    cadenzaGiorni: scadenza.cadenzaGiorni ?? undefined,
                    casaRel: { connect: { id: idCasa } },
                  },
                  update: {
                    nome: scadenza.nome,
                    descrizione: scadenza.descrizione,
                    dataScadenza: scadenza.dataScadenza,
                    isRicorrente: scadenza.isRicorrente,
                    cadenzaGiorni: scadenza.cadenzaGiorni ?? undefined,
                  },
                },
              },
            }
          : {}),
      };

      if (data.anticipataDa !== undefined) {
        updateData.anticipataDaRel = data.anticipataDa
          ? { connect: { id: data.anticipataDa } }
          : { disconnect: true };
      }

      await tx.spesa.update({
        where: { id: idSpesa },
        data: updateData,
      });

      if (quote) {
        await tx.quotaSpesa.deleteMany({ where: { idSpesa, idCasa } });

        if (quote.length) {
          await tx.quotaSpesa.createMany({
            data: quote.map((q) => ({
              idCasa,
              idSpesa,
              idUtente: q.idUtente,
              quota: q.quota,
              OR: [
                { dataPagamento: null },
                { dataPagamento: { isSet: false } },
              ],
            })),
          });
        }
      }

      return tx.spesa.findFirstOrThrow({
        where: { id: idSpesa, idCasa },
        include: INCLUDE_SPESA_BASE,
      });
    });
  }

  async deleteSpesa(
    idCasa: string,
    idSpesa: string,
    idScadenza?: string | null,
  ): Promise<void> {
    await prisma.$transaction(async (tx) => {
      await tx.quotaSpesa.deleteMany({ where: { idSpesa, idCasa } });
      await tx.spesa.delete({ where: { id: idSpesa } });
      if (idScadenza) {
        await tx.scadenza.delete({ where: { id: idScadenza } });
      }
    });
  }

  async findSpeseByCasa(idCasa: string): Promise<SpesaConRelazioni[]> {
    return prisma.spesa.findMany({
      where: { idCasa },
      include: INCLUDE_SPESA_BASE,
    });
  }

  async findSpesaByIdOrThrow(
    idCasa: string,
    idSpesa: string,
  ): Promise<SpesaConRelazioni> {
    return prisma.spesa.findFirstOrThrow({
      where: { id: idSpesa, idCasa },
      include: INCLUDE_SPESA_BASE,
    });
  }

  async findQuoteByIdOrThrow(
    idCasa: string,
    idSpesa: string,
    idQuota: string,
  ): Promise<QuotaConRelazioni> {
    return prisma.quotaSpesa.findFirstOrThrow({
      where: { id: idQuota, idCasa, idSpesa },
      include: INCLUDE_QUOTA_WITH_SPESA,
    });
  }

  async findQuoteBySpesa(
    idCasa: string,
    idSpesa: string,
  ): Promise<QuotaConRelazioni[]> {
    return prisma.quotaSpesa.findMany({
      where: { idCasa, idSpesa },
      include: INCLUDE_QUOTA_WITH_SPESA,
    });
  }

  async markQuotaPagata(idQuota: string): Promise<QuotaConRelazioni> {
    return prisma.quotaSpesa.update({
      where: { id: idQuota },
      data: { dataPagamento: new Date() },
      include: INCLUDE_QUOTA_WITH_SPESA,
    });
  }

  async saldaQuoteVersoCreditori(
    idCasa: string,
    idUtente: string,
    idCreditori: string[],
  ): Promise<number> {
    const result = await prisma.quotaSpesa.updateMany({
      where: {
        idCasa,
        idUtente,
        OR: [{ dataPagamento: null }, { dataPagamento: { isSet: false } }],
        spesaRel: {
          anticipataDa: { in: idCreditori },
        },
      },
      data: { dataPagamento: new Date() },
    });

    return result.count;
  }

  async sumDebito(idCasa: string, idUtente: string): Promise<number> {
    const result = await prisma.quotaSpesa.aggregate({
      where: {
        idCasa,
        idUtente,
        OR: [{ dataPagamento: null }, { dataPagamento: { isSet: false } }],
      },
      _sum: { quota: true },
    });

    return result._sum.quota ?? 0;
  }

  async sumCredito(idCasa: string, idUtente: string): Promise<number> {
    const result = await prisma.quotaSpesa.aggregate({
      where: {
        idCasa,
        OR: [{ dataPagamento: null }, { dataPagamento: { isSet: false } }],
        spesaRel: { anticipataDa: idUtente },
      },
      _sum: { quota: true },
    });

    return result._sum.quota ?? 0;
  }

  async sumCreditoVersoUtente(
    idCasa: string,
    idUtente: string,
    idInquilino: string,
  ): Promise<number> {
    const result = await prisma.quotaSpesa.aggregate({
      where: {
        idCasa,
        idUtente: idInquilino,
        OR: [{ dataPagamento: null }, { dataPagamento: { isSet: false } }],
        spesaRel: { anticipataDa: idUtente },
      },
      _sum: { quota: true },
    });

    return result._sum.quota ?? 0;
  }

  async sumDebitoVersoUtente(
    idCasa: string,
    idUtente: string,
    idInquilino: string,
  ): Promise<number> {
    const result = await prisma.quotaSpesa.aggregate({
      where: {
        idCasa,
        idUtente,
        OR: [{ dataPagamento: null }, { dataPagamento: { isSet: false } }],
        spesaRel: { anticipataDa: idInquilino },
      },
      _sum: { quota: true },
    });

    return result._sum.quota ?? 0;
  }
}
