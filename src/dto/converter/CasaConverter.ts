import { Ruolo } from "@prisma/client";
import { CasaResponseDto, CasaSummaryDto, InquilinoDto } from "../CasaDto";

interface UtenteInfo {
  id: string;
  username: string;
}

interface MembroForDto {
  id: string;
  idUtente: string;
  ruolo: Ruolo;
  dataIngresso: Date;
  utenteRel?: UtenteInfo | null;
}

interface CasaForDto {
  id: string;
  nome: string;
  indirizzo: string;
  citta: string;
  inviteLink: string;
  tipoCasa: string;
  dataCreazione: Date;
  creatorRel?: UtenteInfo | null;
  membri?: MembroForDto[] | null;
}

function toUtenteInfo(rel?: UtenteInfo | null, fallbackId = ""): UtenteInfo {
  return {
    id: rel?.id ?? fallbackId,
    username: rel?.username ?? "",
  };
}

function toInquilinoDto(membro: MembroForDto): InquilinoDto {
  return {
    id: membro.id,
    utente: toUtenteInfo(membro.utenteRel, membro.idUtente),
    ruolo: membro.ruolo,
    dataIngresso: membro.dataIngresso,
  };
}

function resolveRuoloUtente(
  membri: MembroForDto[] | null | undefined,
  idUtente?: string,
): Ruolo {
  const membro = membri?.find((item) => item.idUtente === idUtente);
  return membro?.ruolo ?? Ruolo.Inquilino;
}

function baseCasaDto(casa: CasaForDto, idUtente?: string): CasaSummaryDto {
  const membri = Array.isArray(casa.membri) ? casa.membri : [];

  return {
    id: casa.id,
    nome: casa.nome,
    indirizzo: casa.indirizzo,
    citta: casa.citta,
    tipoCasa: casa.tipoCasa,
    inviteLink: casa.inviteLink,
    dataCreazione: casa.dataCreazione,
    creator: toUtenteInfo(casa.creatorRel),
    ruoloUtente: resolveRuoloUtente(membri, idUtente),
    membriTotali: membri.length,
  };
}

export class CasaConverter {
  toSummaryDto(casa: CasaForDto, idUtente?: string): CasaSummaryDto {
    return baseCasaDto(casa, idUtente);
  }

  toCasaDto(casa: CasaForDto, idUtente?: string): CasaResponseDto {
    const membri = Array.isArray(casa.membri) ? casa.membri : [];

    return {
      ...baseCasaDto(casa, idUtente),
      membri: membri.map((membro) => toInquilinoDto(membro)),
    };
  }

  toInquilinoDto(membro: MembroForDto): InquilinoDto {
    return toInquilinoDto(membro);
  }
}
