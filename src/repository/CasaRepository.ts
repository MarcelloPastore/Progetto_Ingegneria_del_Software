import { Ruolo } from "@prisma/client";

import { prisma } from "../config/db";
import { CreaCasaDto } from "../dto/CasaDto";

export class CasaRepository {
  private readonly casaSelect = {
    id: true,
    nome: true,
    indirizzo: true,
    citta: true,
    tipoCasa: true,
    inviteLink: true,
  };

  async createCasa(
    data: CreaCasaDto,
    idUtente: string,
    inviteLink: string,
  ) {
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

  async getMembriCasaIds(idCasa: string): Promise<string[]> {
    const membri = await prisma.membroCasa.findMany({
      where: { idCasa },
      select: { idUtente: true },
    });

    return membri.map((m: { idUtente: string }) => m.idUtente);
  }
}
