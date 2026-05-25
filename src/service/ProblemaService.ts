import { Priorita, Stato } from "@prisma/client";
import {
  AggiornaPrioritaDto,
  AggiornaStatoDto,
  AssegnaProblemaDto,
  CreaProblemaDto,
  ProblemaListItemDto,
  ProblemaResponseDto,
} from "../dto/ProblemaDto";
import { ProblemaConverter } from "../dto/converter/ProblemaConverter";
import { ProblemaRepository } from "../repository/ProblemaRepository";

const problemaRepository = new ProblemaRepository();
const problemaConverter = new ProblemaConverter();

export class ProblemaService {
  async getAllProblemi(idCasa: string): Promise<ProblemaListItemDto[]> {
    const problemi = await problemaRepository.findProblemiByCasa(idCasa);

    return problemi.map((p) => problemaConverter.toListItemDto(p));
  }

  async getProblemiIrrisolti(idCasa: string): Promise<ProblemaResponseDto[]> {
    const problemi = await problemaRepository.findProblemiNonRisolti(idCasa);

    return problemi.map((p) => problemaConverter.toDto(p));
  }

  async getProblema(
    idCasa: string,
    idProblema: string,
  ): Promise<ProblemaResponseDto> {
    const problema = await problemaRepository.findProblemaByIdOrThrow(
      idCasa,
      idProblema,
    );

    return problemaConverter.toDto(problema);
  }

  async segnalaProblema(
    idCasa: string,
    dto: CreaProblemaDto,
    idUtente: string,
  ): Promise<ProblemaResponseDto> {
    const problema = await problemaRepository.createProblema({
      idCasa,
      nome: dto.nome,
      descrizione: dto.descrizione,
      segnalataDa: idUtente,
      ...(dto.priorita ? { priorita: dto.priorita } : {}),
    });

    return problemaConverter.toDto(problema);
  }

  async eliminaProblema(idCasa: string, idProblema: string): Promise<void> {
    await problemaRepository.deleteProblema(idCasa, idProblema);
  }

  async autoassegnaProblema(
    idCasa: string,
    idProblema: string,
    idUtente: string,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    const problema = await problemaRepository.updateProblema(idProblema, {
      assegnatario: idUtente,
      stato: Stato.Assegnato,
      dataRisoluzione: null,
    });

    return problemaConverter.toDto(problema);
  }

  async assegnaProblema(
    idCasa: string,
    idProblema: string,
    dto: AssegnaProblemaDto,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    const assegnatario = dto.idUtente ?? null;
    const stato = assegnatario ? Stato.Assegnato : Stato.Segnalato;

    const problema = await problemaRepository.updateProblema(idProblema, {
      assegnatario,
      stato,
      dataRisoluzione: null,
    });

    return problemaConverter.toDto(problema);
  }

  async aggiornaStato(
    idCasa: string,
    idProblema: string,
    dto: AggiornaStatoDto,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    const dataRisoluzione = dto.stato === Stato.Risolto ? new Date() : null;

    const problema = await problemaRepository.updateProblema(idProblema, {
      stato: dto.stato,
      dataRisoluzione,
    });

    return problemaConverter.toDto(problema);
  }

  async aggiornaPriorita(
    idCasa: string,
    idProblema: string,
    dto: AggiornaPrioritaDto,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    const problema = await problemaRepository.updateProblema(idProblema, {
      priorita: dto.priorita ?? Priorita.Media,
    });

    return problemaConverter.toDto(problema);
  }
}
