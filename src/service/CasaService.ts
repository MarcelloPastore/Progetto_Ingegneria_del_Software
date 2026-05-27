import { randomUUID } from "crypto";
import { Ruolo } from "@prisma/client";
import {
  AggiungiInquilinoDto,
  CasaResponseDto,
  CasaSummaryDto,
  CreaCasaDto,
  InquilinoDto,
  InviteLinkDto,
  ModificaRuoloDto,
} from "../dto/CasaDto";
import { CasaConverter } from "../dto/converter/CasaConverter";
import {
  CasaRepository,
  MembroCasaConUtente,
} from "../repository/CasaRepository";
import { ConflictError, ForbiddenError } from "../errors/httpErrors";

const casaRepository = new CasaRepository();
const casaConverter = new CasaConverter();

function isHomeAdmin(membro: MembroCasaConUtente): boolean {
  return membro.ruolo === Ruolo.HomeAdmin;
}

export class CasaService {
  private async assertMembroCasa(idCasa: string, idUtente: string) {
    return casaRepository.findMembroCasaByCasaAndUtenteOrThrow(
      idCasa,
      idUtente,
    );
  }

  private async assertHomeAdmin(idCasa: string, idUtente: string) {
    const membro = await this.assertMembroCasa(idCasa, idUtente);

    if (!isHomeAdmin(membro)) {
      throw new ForbiddenError("Solo un HomeAdmin puo eseguire questa azione");
    }

    return membro;
  }

  async creaCasa(
    dto: CreaCasaDto,
    idCreatore: string,
  ): Promise<CasaResponseDto> {
    const casa = await casaRepository.createCasa({
      ...dto,
      creator: idCreatore,
      inviteLink: randomUUID(),
    });

    return casaConverter.toCasaDto(casa, idCreatore);
  }

  async getCase(idUtente: string): Promise<CasaSummaryDto[]> {
    const caseUtente = await casaRepository.findCaseByUser(idUtente);

    return caseUtente.map((casa) => casaConverter.toSummaryDto(casa, idUtente));
  }

  async getCasa(idCasa: string, idUtente: string): Promise<CasaResponseDto> {
    await this.assertMembroCasa(idCasa, idUtente);

    const casa = await casaRepository.findCasaByIdOrThrow(idCasa);
    return casaConverter.toCasaDto(casa, idUtente);
  }

  async eliminaCasa(idCasa: string, idUtente: string): Promise<void> {
    await this.assertHomeAdmin(idCasa, idUtente);
    await casaRepository.deleteCasa(idCasa);
  }

  async getAllInquilini(
    idCasa: string,
    idUtente: string,
  ): Promise<InquilinoDto[]> {
    await this.assertMembroCasa(idCasa, idUtente);

    const casa = await casaRepository.findCasaByIdOrThrow(idCasa);
    return casa.membri.map((membro) => casaConverter.toInquilinoDto(membro));
  }

  async getInquilino(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<InquilinoDto> {
    await this.assertMembroCasa(idCasa, idUtente);

    const membro = await casaRepository.findMembroCasaByCasaAndUtenteOrThrow(
      idCasa,
      idInquilino,
    );

    return casaConverter.toInquilinoDto(membro);
  }

  async aggiungiInquilino(
    idCasa: string,
    dto: AggiungiInquilinoDto,
    idUtente: string,
  ): Promise<InquilinoDto> {
    await casaRepository.findCasaByIdAndInviteLinkOrThrow(
      idCasa,
      dto.inviteLink,
    );

    const giaPresente = await casaRepository.findMembroCasaByCasaAndUtente(
      idCasa,
      idUtente,
    );

    if (giaPresente) {
      throw new ConflictError("L'utente fa gia parte della casa");
    }

    const membro = await casaRepository.addMembroCasa(idCasa, idUtente);
    return casaConverter.toInquilinoDto(membro);
  }

  async rimuoviInquilino(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<void> {
    await this.assertHomeAdmin(idCasa, idUtente);
    await casaRepository.removeMembroCasa(idCasa, idInquilino);
  }

  async modificaRuolo(
    idCasa: string,
    idInquilino: string,
    dto: ModificaRuoloDto,
    idUtente: string,
  ): Promise<InquilinoDto> {
    await this.assertHomeAdmin(idCasa, idUtente);

    const membro = await casaRepository.updateMembroCasaRole(
      idCasa,
      idInquilino,
      dto.ruolo,
    );

    return casaConverter.toInquilinoDto(membro);
  }

  async generaLink(
    idCasa: string,
    idUtente: string,
    rigenera = false,
  ): Promise<InviteLinkDto> {
    await this.assertHomeAdmin(idCasa, idUtente);

    if (!rigenera) {
      const casa = await casaRepository.findCasaByIdOrThrow(idCasa);
      return { inviteLink: casa.inviteLink };
    }

    const aggiornata = await casaRepository.updateCasa(idCasa, {
      inviteLink: randomUUID(),
    });

    return { inviteLink: aggiornata.inviteLink };
  }
}
