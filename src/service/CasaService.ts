import { randomUUID } from "node:crypto";
import { Ruolo } from "@prisma/client";
import {
  AggiungiInquilinoDto,
  CasaResponseDto,
  CasaSummaryDto,
  CreaCasaDto,
  InquilinoDto,
  InviteLinkDto,
  ModificaCasaDto,
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
    const indirizzo: string = dto.indirizzo ?? "";
    const citta: string = dto.citta ?? "";
    const tipoCasa: string = dto.tipoCasa ?? "";
    const casa = await casaRepository.createCasa({
      nome: dto.nome,
      indirizzo,
      citta,
      tipoCasa,
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

  async modificaCasa(
    idCasa: string,
    idUtente: string,
    dto: ModificaCasaDto,
  ): Promise<CasaResponseDto> {
    await this.assertHomeAdmin(idCasa, idUtente);
    const casa = await casaRepository.updateCasa(idCasa, dto);

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

    const ownerIdCasa = await casaRepository.getCasaCreator(idCasa);
    if (ownerIdCasa && idInquilino === ownerIdCasa) {
      throw new ForbiddenError(
        "Il proprietario della casa non può essere rimosso",
      );
    }

    await casaRepository.removeMembroCasa(idCasa, idInquilino);
  }

  async modificaRuolo(
    idCasa: string,
    idInquilino: string,
    dto: ModificaRuoloDto,
    idUtente: string,
  ): Promise<InquilinoDto> {
    await this.assertHomeAdmin(idCasa, idUtente);

    const ownerIdCasa = await casaRepository.getCasaCreator(idCasa);
    if (ownerIdCasa && idInquilino === ownerIdCasa) {
      throw new ForbiddenError(
        "Il ruolo del proprietario della casa non può essere modificato",
      );
    }

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

  async selectCasa(
    idCasa: string,
    idUtente: string,
  ): Promise<{ idCasa: string; ruoloCasa: Ruolo }> {
    const membro = await this.assertMembroCasa(idCasa, idUtente);
    return { idCasa, ruoloCasa: membro.ruolo };
  }
}

import { Ruolo } from "@prisma/client";

import { CasaRepository } from "../repository/CasaRepository";
import {
  AggiungiInquilinoDto,
  CreaCasaDto,
  InquilinoCasaDto,
  ModificaCasaDto,
  ModificaRuoloInquilinoDto,
} from "../dto/CasaDto";
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from "../errors/httpErrors";

export class CasaService {
  constructor(private casaRepository = new CasaRepository()) {}

  async creaCasa(dto: CreaCasaDto, idUtente: string) {
    const inviteCode = this.generateInviteCode();
    const inviteLink = `coincasa.app/join/${inviteCode}`;

    return this.casaRepository.createCasa(dto, idUtente, inviteLink);
  }

  async getCase(idUtente: string) {
    const caseUtente = await this.casaRepository.getCaseByUtente(idUtente);

    return Promise.all(
      caseUtente.map(async (casa) => ({
        ...casa,
        ruolo: (await this.casaRepository.getMembroCasa(casa.id, idUtente))
          ?.ruolo,
      })),
    );
  }

  async getCasa(idCasa: string, idUtente: string) {
    const casa = await this.casaRepository.getCasaByIdAndUtente(
      idCasa,
      idUtente,
    );

    if (!casa) {
      throw new NotFoundError("Casa non trovata");
    }

    const membro = await this.casaRepository.getMembroCasa(idCasa, idUtente);

    return { ...casa, ruolo: membro?.ruolo };
  }

  async modificaCasa(idCasa: string, dto: ModificaCasaDto, idUtente: string) {
    await this.assertHomeAdmin(idCasa, idUtente);

    const casa = await this.casaRepository.updateCasa(idCasa, dto);
    const membro = await this.casaRepository.getMembroCasa(idCasa, idUtente);

    return { ...casa, ruolo: membro?.ruolo };
  }

  async eliminaCasa(idCasa: string, idUtente: string): Promise<void> {
    await this.assertHomeAdmin(idCasa, idUtente);

    await this.casaRepository.deleteCasa(idCasa);
  }

  async getInquilini(idCasa: string, idUtente: string) {
    await this.assertMembroCasa(idCasa, idUtente);

    const [membri, ownerIdCasa] = await Promise.all([
      this.casaRepository.getMembriCasa(idCasa),
      this.casaRepository.getCasaCreator(idCasa),
    ]);
    return membri.map((membro) => this.toInquilinoDto(membro, ownerIdCasa));
  }

  async getInquilino(idCasa: string, idInquilino: string, idUtente: string) {
    await this.assertMembroCasa(idCasa, idUtente);

    const membro = await this.casaRepository.getMembroCasa(idCasa, idInquilino);
    if (!membro) {
      throw new NotFoundError("Inquilino non trovato");
    }

    return this.toInquilinoDto(membro);
  }

  async aggiungiInquilino(
    idCasa: string,
    dto: AggiungiInquilinoDto,
    idUtente: string,
  ) {
    const idNuovoInquilino = dto.idUtente ?? idUtente;

    if (idNuovoInquilino !== idUtente) {
      await this.assertHomeAdmin(idCasa, idUtente);
    }

    const casa = await this.casaRepository.getCasaById(idCasa);
    if (!casa) {
      throw new NotFoundError("Casa non trovata");
    }

    if (!this.inviteMatches(dto, casa.inviteLink)) {
      throw new ForbiddenError("Codice di invito non valido");
    }

    const membroEsistente = await this.casaRepository.getMembroCasa(
      idCasa,
      idNuovoInquilino,
    );
    if (membroEsistente) {
      throw new ConflictError("Utente gia presente nella casa");
    }

    const nuovoMembro = await this.casaRepository.addMembroCasa(
      idCasa,
      idNuovoInquilino,
    );

    return this.toInquilinoDto(nuovoMembro);
  }

  async entraConCodiceInvito(dto: AggiungiInquilinoDto, idUtente: string) {
    const provided = dto.inviteLink ?? dto.inviteCode ?? dto.codiceInvito;
    if (!provided) {
      throw new ForbiddenError("Codice di invito non valido");
    }

    const casa = await this.casaRepository.getCasaByInviteCodeOrLink(provided);
    if (!casa || !this.inviteMatches(dto, casa.inviteLink)) {
      throw new ForbiddenError("Codice di invito non valido");
    }

    const membroEsistente = await this.casaRepository.getMembroCasa(
      casa.id,
      idUtente,
    );
    if (membroEsistente) {
      return { ...casa, ruolo: membroEsistente.ruolo };
    }

    const nuovoMembro = await this.casaRepository.addMembroCasa(
      casa.id,
      idUtente,
    );

    return { ...casa, ruolo: nuovoMembro.ruolo };
  }

  async rimuoviInquilino(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<void> {
    await this.assertHomeAdmin(idCasa, idUtente);

    const ownerIdCasa = await this.casaRepository.getCasaCreator(idCasa);
    if (ownerIdCasa && idInquilino === ownerIdCasa) {
      throw new ForbiddenError("Il proprietario della casa non può essere rimosso");
    }

    const membro = await this.casaRepository.getMembroCasa(idCasa, idInquilino);
    if (!membro) {
      throw new NotFoundError("Inquilino non trovato");
    }

    await this.ensureNotLastHomeAdmin(idCasa, membro.ruolo);
    await this.casaRepository.removeMembroCasa(idCasa, idInquilino);
  }

  async modificaRuoloInquilino(
    idCasa: string,
    idInquilino: string,
    dto: ModificaRuoloInquilinoDto,
    idUtente: string,
  ) {
    await this.assertHomeAdmin(idCasa, idUtente);

    const ownerIdCasa = await this.casaRepository.getCasaCreator(idCasa);
    if (ownerIdCasa && idInquilino === ownerIdCasa) {
      throw new ForbiddenError("Il ruolo del proprietario della casa non può essere modificato");
    }

    const membro = await this.casaRepository.getMembroCasa(idCasa, idInquilino);
    if (!membro) {
      throw new NotFoundError("Inquilino non trovato");
    }

    if (membro.ruolo === Ruolo.HomeAdmin && dto.ruolo !== Ruolo.HomeAdmin) {
      await this.ensureNotLastHomeAdmin(idCasa, membro.ruolo);
    }

    const aggiornato = await this.casaRepository.updateRuoloMembro(
      idCasa,
      idInquilino,
      dto.ruolo,
    );

    return this.toInquilinoDto(aggiornato);
  }

  private generateInviteCode() {
    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    const randomPart = Array.from({ length: 6 }, () => {
      const index = Math.floor(Math.random() * alphabet.length);
      return alphabet[index];
    }).join("");

    return `CX-${randomPart}`;
  }

  private async assertMembroCasa(idCasa: string, idUtente: string) {
    const membro = await this.casaRepository.getMembroCasa(idCasa, idUtente);

    if (!membro) {
      throw new NotFoundError("Casa non trovata");
    }

    return membro;
  }

  private async assertHomeAdmin(idCasa: string, idUtente: string) {
    const membro = await this.assertMembroCasa(idCasa, idUtente);

    if (membro.ruolo !== Ruolo.HomeAdmin && membro.ruolo !== Ruolo.SysAdmin) {
      throw new ForbiddenError("Solo un HomeAdmin puo eseguire questa azione");
    }

    return membro;
  }

  private async ensureNotLastHomeAdmin(idCasa: string, ruolo: Ruolo) {
    if (ruolo !== Ruolo.HomeAdmin) {
      return;
    }

    const homeAdminCount = await this.casaRepository.countHomeAdmin(idCasa);
    if (homeAdminCount <= 1) {
      throw new ConflictError("La casa deve avere almeno un HomeAdmin");
    }
  }

  private inviteMatches(dto: AggiungiInquilinoDto, inviteLink: string) {
    const expectedCode = inviteLink.split("/").pop();
    const provided = dto.inviteLink ?? dto.inviteCode ?? dto.codiceInvito;

    return provided === inviteLink || provided === expectedCode;
  }

  private toInquilinoDto(
    membro: {
      id: string;
      idUtente: string;
      ruolo: Ruolo;
      dataIngresso: Date;
      utenteRel: {
        id: string;
        username: string;
        nome: string;
        cognome: string;
        email: string;
      };
    },
    ownerIdCasa: string | null = null,
  ): InquilinoCasaDto {
    return {
      id: membro.utenteRel.id,
      idUtente: membro.idUtente,
      nome: membro.utenteRel.nome,
      cognome: membro.utenteRel.cognome,
      username: membro.utenteRel.username,
      email: membro.utenteRel.email,
      ruolo: membro.ruolo,
      dataIngresso: membro.dataIngresso.toISOString(),
      isOwner: ownerIdCasa !== null && membro.idUtente === ownerIdCasa,
    };
  }
}
