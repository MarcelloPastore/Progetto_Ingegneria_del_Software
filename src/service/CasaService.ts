import { CasaRepository } from "../repository/CasaRepository";
import { CreaCasaDto } from "../dto/CasaDto";
import { NotFoundError } from "../errors/httpErrors";

export class CasaService {
  constructor(private casaRepository = new CasaRepository()) {}

  async creaCasa(dto: CreaCasaDto, idUtente: string) {
    const inviteCode = this.generateInviteCode();
    const inviteLink = `coincasa.app/join/${inviteCode}`;

    return this.casaRepository.createCasa(dto, idUtente, inviteLink);
  }

  async getCase(idUtente: string) {
    return this.casaRepository.getCaseByUtente(idUtente);
  }

  async getCasa(idCasa: string, idUtente: string) {
    const casa = await this.casaRepository.getCasaByIdAndUtente(
      idCasa,
      idUtente,
    );

    if (!casa) {
      throw new NotFoundError("Casa non trovata");
    }

    return casa;
  }

  private generateInviteCode() {
    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    const randomPart = Array.from({ length: 6 }, () => {
      const index = Math.floor(Math.random() * alphabet.length);
      return alphabet[index];
    }).join("");

    return `CX-${randomPart}`;
  }
}
