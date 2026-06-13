import { ProblemaListItemDto, ProblemaResponseDto } from "../ProblemaDto";

interface ProblemaForDto {
  id: string;
  nome: string;
  descrizione: string;
  priorita: string;
  stato: string;
  segnalataDa: string;
  segnalataDaRel?: { id: string; username: string } | null;
  assegnatario?: string | null;
  assegnatarioRel?: { id: string; username: string } | null;
  dataCreazione: Date;
  dataRisoluzione?: Date | null;
}

export class ProblemaConverter {
  toListItemDto(problema: ProblemaForDto): ProblemaListItemDto {
    const assegnatarioRel = problema.assegnatarioRel;
    let assegnatario: ProblemaListItemDto["assegnatario"] = null;

    if (assegnatarioRel) {
      assegnatario = {
        id: assegnatarioRel.id,
        username: assegnatarioRel.username,
      };
    } else if (problema.assegnatario) {
      assegnatario = { id: problema.assegnatario, username: "" };
    }

    return {
      id: problema.id,
      nome: problema.nome,
      descrizione: problema.descrizione,
      assegnatario,
      priorita: problema.priorita as ProblemaListItemDto["priorita"],
      stato: problema.stato as ProblemaListItemDto["stato"],
    };
  }

  toDto(problema: ProblemaForDto): ProblemaResponseDto {
    const segnalataRel = problema.segnalataDaRel;
    const assegnatarioRel = problema.assegnatarioRel;
    let assegnatario: ProblemaResponseDto["assegnatario"] = null;

    if (assegnatarioRel) {
      assegnatario = {
        id: assegnatarioRel.id,
        username: assegnatarioRel.username,
      };
    } else if (problema.assegnatario) {
      assegnatario = { id: problema.assegnatario, username: "" };
    }

    return {
      id: problema.id,
      nome: problema.nome,
      descrizione: problema.descrizione,
      priorita: problema.priorita as ProblemaResponseDto["priorita"],
      stato: problema.stato as ProblemaResponseDto["stato"],
      segnalataDa: {
        id: segnalataRel?.id ?? problema.segnalataDa,
        username: segnalataRel?.username ?? "",
      },
      assegnatario,
      dataCreazione: problema.dataCreazione.toISOString(),
      dataRisoluzione: problema.dataRisoluzione?.toISOString() ?? null,
    };
  }
}
