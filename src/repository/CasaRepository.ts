import { Ruolo } from "@prisma/client";

import { prisma } from "../config/db";
import { CreaCasaDto } from "../dto/CasaDto";

const membroSelect = {
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
};

export class CasaRepository {
  private readonly casaSelect = {
    id: true,
    nome: true,
    indirizzo: true,
    citta: true,
    tipoCasa: true,
    inviteLink: true,
  };

  async createCasa(data: CreaCasaDto, idUtente: string, inviteLink: string) {
    return prisma.casa.create({
      data: {
        nome: data.nome,
        indirizzo: data.indirizzo,
        citta: data.citta,
        tipoCasa: data.tipoCasa,
        inviteLink,
        creatorRel: { connect: { id: idUtente } },
        membri: {
          create: {
            ruolo: Ruolo.HomeAdmin,
            utenteRel: { connect: { id: idUtente } },
          },
        },
      },
      select: this.casaSelect,
    });
  }

  async getCaseByUtente(idUtente: string) {
    return prisma.casa.findMany({
      where: {
        OR: [{ creator: idUtente }, { membri: { some: { idUtente } } }],
      },
      select: this.casaSelect,
      orderBy: { dataCreazione: "desc" },
    });
  }

  async getCasaByIdAndUtente(idCasa: string, idUtente: string) {
    return prisma.casa.findFirst({
      where: {
        id: idCasa,
        OR: [{ creator: idUtente }, { membri: { some: { idUtente } } }],
      },
      select: this.casaSelect,
    });
  }

  async getCasaById(idCasa: string) {
    return prisma.casa.findUnique({
      where: { id: idCasa },
      select: this.casaSelect,
    });
  }

  async getCasaByInviteCodeOrLink(inviteCodeOrLink: string) {
    return prisma.casa.findFirst({
      where: {
        OR: [
          { inviteLink: inviteCodeOrLink },
          { inviteLink: { endsWith: `/${inviteCodeOrLink}` } },
        ],
      },
      select: this.casaSelect,
    });
  }

  async updateCasa(idCasa: string, data: Partial<CreaCasaDto>) {
    return prisma.casa.update({
      where: { id: idCasa },
      data: {
        ...(data.nome !== undefined && { nome: data.nome }),
        ...(data.indirizzo !== undefined && { indirizzo: data.indirizzo }),
        ...(data.citta !== undefined && { citta: data.citta }),
        ...(data.tipoCasa !== undefined && { tipoCasa: data.tipoCasa }),
      },
      select: this.casaSelect,
    });
  }

  async deleteCasa(idCasa: string) {
    const problemi = await prisma.problema.findMany({
      where: { idCasa },
      select: { id: true },
    });
    const idProblemi = problemi.map((p) => p.id);

    await prisma.storico.deleteMany({
      where: { idProblema: { in: idProblemi } },
    });
    await prisma.documento.deleteMany({ where: { idCasa } });
    await prisma.problema.deleteMany({ where: { idCasa } });
    await prisma.turno.deleteMany({ where: { idCasa } });
    await prisma.scadenza.deleteMany({ where: { idCasa } });
    await prisma.quotaSpesa.deleteMany({ where: { idCasa } });
    await prisma.spesa.deleteMany({ where: { idCasa } });
    await prisma.membroCasa.deleteMany({ where: { idCasa } });
    await prisma.casa.delete({ where: { id: idCasa } });
  }

  async getMembroCasa(idCasa: string, idUtente: string) {
    return prisma.membroCasa.findUnique({
      where: { idUtente_idCasa: { idUtente, idCasa } },
      select: membroSelect,
    });
  }

  async getMembriCasa(idCasa: string) {
    return prisma.membroCasa.findMany({
      where: { idCasa },
      select: membroSelect,
      orderBy: { dataIngresso: "asc" },
    });
  }

  async addMembroCasa(idCasa: string, idUtente: string) {
    return prisma.membroCasa.create({
      data: {
        idCasa,
        idUtente,
        ruolo: Ruolo.Inquilino,
      },
      select: membroSelect,
    });
  }

  async updateRuoloMembro(idCasa: string, idUtente: string, ruolo: Ruolo) {
    return prisma.membroCasa.update({
      where: { idUtente_idCasa: { idUtente, idCasa } },
      data: { ruolo },
      select: membroSelect,
    });
  }

  async removeMembroCasa(idCasa: string, idUtente: string) {
    await prisma.membroCasa.delete({
      where: { idUtente_idCasa: { idUtente, idCasa } },
    });
  }

  async countHomeAdmin(idCasa: string) {
    return prisma.membroCasa.count({
      where: { idCasa, ruolo: Ruolo.HomeAdmin },
    });
  }

  async getMembriCasaIds(idCasa: string): Promise<string[]> {
    const membri = await prisma.membroCasa.findMany({
      where: { idCasa },
      select: { idUtente: true },
    });

    return membri.map((m: { idUtente: string }) => m.idUtente);
  }
}
