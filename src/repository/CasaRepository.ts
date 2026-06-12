import { Ruolo } from "@prisma/client";
import { prisma } from "../config/db";

export const INCLUDE_CASA_CON_REL = {
  creatorRel: {
    select: { id: true, username: true },
  },
  membri: {
    select: {
      id: true,
      idUtente: true,
      ruolo: true,
      dataIngresso: true,
      utenteRel: {
        select: {
          id: true,
          username: true,
          nome: true,
          cognome: true,
          email: true,
        },
      },
    },
  },
} as const;

export const INCLUDE_MEMBRO_CON_UTENTE = {
  utenteRel: {
    select: {
      id: true,
      username: true,
      nome: true,
      cognome: true,
      email: true,
    },
  },
} as const;

const _casaQuery = () =>
  prisma.casa.findFirst({ include: INCLUDE_CASA_CON_REL });
const _membroQuery = () =>
  prisma.membroCasa.findFirst({ include: INCLUDE_MEMBRO_CON_UTENTE });

export type CasaConRelazioni = NonNullable<
  Awaited<ReturnType<typeof _casaQuery>>
>;
export type MembroCasaConUtente = NonNullable<
  Awaited<ReturnType<typeof _membroQuery>>
>;

type CasaCreateData = {
  nome: string;
  indirizzo: string;
  citta: string;
  tipoCasa: string;
  creator: string;
  inviteLink: string;
};

type CasaUpdateData = Partial<{
  nome: string;
  indirizzo: string;
  citta: string;
  tipoCasa: string;
  inviteLink: string;
}>;

export class CasaRepository {
  async createCasa(data: CasaCreateData): Promise<CasaConRelazioni> {
    return prisma.casa.create({
      data: {
        nome: data.nome,
        indirizzo: data.indirizzo,
        citta: data.citta,
        tipoCasa: data.tipoCasa,
        inviteLink: data.inviteLink,
        creatorRel: { connect: { id: data.creator } },
        membri: {
          create: {
            ruolo: Ruolo.HomeAdmin,
            utenteRel: { connect: { id: data.creator } },
          },
        },
      },
      include: INCLUDE_CASA_CON_REL,
    });
  }

  async findCaseByUser(idUtente: string): Promise<CasaConRelazioni[]> {
    return prisma.casa.findMany({
      where: { membri: { some: { idUtente } } },
      include: INCLUDE_CASA_CON_REL,
    });
  }

  async findCasaByIdOrThrow(idCasa: string): Promise<CasaConRelazioni> {
    return prisma.casa.findFirstOrThrow({
      where: { id: idCasa },
      include: INCLUDE_CASA_CON_REL,
    });
  }

  async findCasaByIdAndInviteLinkOrThrow(
    idCasa: string,
    inviteLink: string,
  ): Promise<CasaConRelazioni> {
    return prisma.casa.findFirstOrThrow({
      where: { id: idCasa, inviteLink },
      include: INCLUDE_CASA_CON_REL,
    });
  }

  async updateCasa(
    idCasa: string,
    data: CasaUpdateData,
  ): Promise<CasaConRelazioni> {
    return prisma.casa.update({
      where: { id: idCasa },
      data,
      include: INCLUDE_CASA_CON_REL,
    });
  }

  async deleteCasa(idCasa: string): Promise<void> {
    await prisma.$transaction(async (tx) => {
      await tx.quotaSpesa.deleteMany({ where: { idCasa } });
      await tx.spesa.deleteMany({ where: { idCasa } });
      await tx.turno.deleteMany({ where: { idCasa } });
      await tx.problema.deleteMany({ where: { idCasa } });
      await tx.documento.deleteMany({ where: { idCasa } });
      await tx.scadenza.deleteMany({ where: { idCasa } });
      await tx.membroCasa.deleteMany({ where: { idCasa } });
      await tx.casa.delete({ where: { id: idCasa } });
    });
  }

  async getMembriCasaIds(idCasa: string): Promise<string[]> {
    const membri = await prisma.membroCasa.findMany({
      where: { idCasa },
      select: { idUtente: true },
    });

    return membri.map((m: { idUtente: string }) => m.idUtente);
  }

  async getCasaCreator(idCasa: string): Promise<string | null> {
    const casa = await prisma.casa.findUnique({
      where: { id: idCasa },
      select: { creator: true },
    });
    return casa?.creator ?? null;
  }

  async findMembroCasaByCasaAndUtente(
    idCasa: string,
    idUtente: string,
  ): Promise<MembroCasaConUtente | null> {
    return prisma.membroCasa.findFirst({
      where: { idCasa, idUtente },
      include: INCLUDE_MEMBRO_CON_UTENTE,
    });
  }

  async findMembroCasaByCasaAndUtenteOrThrow(
    idCasa: string,
    idUtente: string,
  ): Promise<MembroCasaConUtente> {
    return prisma.membroCasa.findFirstOrThrow({
      where: { idCasa, idUtente },
      include: INCLUDE_MEMBRO_CON_UTENTE,
    });
  }

  async addMembroCasa(
    idCasa: string,
    idUtente: string,
    ruolo: Ruolo = Ruolo.Inquilino,
  ): Promise<MembroCasaConUtente> {
    return prisma.membroCasa.create({
      data: {
        ruolo,
        casaRel: { connect: { id: idCasa } },
        utenteRel: { connect: { id: idUtente } },
      },
      include: INCLUDE_MEMBRO_CON_UTENTE,
    });
  }

  async updateMembroCasaRole(
    idCasa: string,
    idUtente: string,
    ruolo: Ruolo,
  ): Promise<MembroCasaConUtente> {
    const membro = await this.findMembroCasaByCasaAndUtenteOrThrow(
      idCasa,
      idUtente,
    );

    return prisma.membroCasa.update({
      where: { id: membro.id },
      data: { ruolo },
      include: INCLUDE_MEMBRO_CON_UTENTE,
    });
  }

  async removeMembroCasa(idCasa: string, idUtente: string): Promise<void> {
    const membro = await this.findMembroCasaByCasaAndUtenteOrThrow(
      idCasa,
      idUtente,
    );

    await prisma.membroCasa.delete({ where: { id: membro.id } });
  }
}
