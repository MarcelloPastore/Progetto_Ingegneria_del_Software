import { prisma } from "../config/db";

export class CasaRepository {
  async getMembriCasaIds(idCasa: string): Promise<string[]> {
    const membri = await prisma.membroCasa.findMany({
      where: { idCasa },
      select: { idUtente: true },
    });

    return membri.map((m: { idUtente: string }) => m.idUtente);
  }
}
