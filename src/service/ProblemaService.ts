import { Priorita, Ruolo, Stato } from "@prisma/client";
import {
  AggiornaPrioritaDto,
  AggiornaStatoDto,
  AssegnaProblemaDto,
  CreaProblemaDto,
  ModificaProblemaDto,
  ProblemaListItemDto,
  ProblemaResponseDto,
} from "../dto/ProblemaDto";
import { ProblemaConverter } from "../dto/converter/ProblemaConverter";
import { ProblemaRepository } from "../repository/ProblemaRepository";
import { CasaRepository } from "../repository/CasaRepository";
import { ForbiddenError } from "../errors/httpErrors";

const problemaRepository = new ProblemaRepository();
const casaRepository = new CasaRepository();
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

  async eliminaProblema(idCasa: string, idProblema: string, idUtente: string): Promise<void> {
    const problema = await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);
    const membro = await casaRepository.findMembroCasaByCasaAndUtenteOrThrow(idCasa, idUtente);
    const isAdmin = membro.ruolo === Ruolo.HomeAdmin || membro.ruolo === Ruolo.SysAdmin;
    if (!isAdmin && problema.segnalataDa !== idUtente) {
      throw new ForbiddenError("Solo chi ha segnalato il problema o un HomeAdmin può eliminarlo");
    }
    await problemaRepository.deleteProblema(idCasa, idProblema);
  }

  async modificaProblema(
    idCasa: string,
    idProblema: string,
    dto: ModificaProblemaDto,
    idUtente: string,
    ruoloCasa?: Ruolo,
  ): Promise<ProblemaResponseDto> {
    const esistente = await problemaRepository.findProblemaByIdOrThrow(
      idCasa,
      idProblema,
    );
    if (
      esistente.segnalataDa !== idUtente &&
      ruoloCasa !== Ruolo.HomeAdmin &&
      ruoloCasa !== Ruolo.SysAdmin
    ) {
      throw new ForbiddenError(
        "Solo chi ha segnalato il problema o un HomeAdmin puo modificarlo",
      );
    }

    const problema = await problemaRepository.updateProblema(idProblema, {
      ...(dto.nome !== undefined && { nome: dto.nome }),
      ...(dto.descrizione !== undefined && { descrizione: dto.descrizione }),
      ...(dto.priorita !== undefined && { priorita: dto.priorita }),
    });

    return problemaConverter.toDto(problema);
  }

  async rinunciaProblema(
    idCasa: string,
    idProblema: string,
    idUtente: string,
  ): Promise<ProblemaResponseDto> {
    const esistente = await problemaRepository.findProblemaByIdOrThrow(
      idCasa,
      idProblema,
    );
    if (esistente.assegnatario !== idUtente) {
      throw new ForbiddenError(
        "Solo l'assegnatario corrente puo rinunciare al problema",
      );
    }

    await problemaRepository.updateProblema(idProblema, {
      assegnatario: null,
      stato: Stato.Segnalato,
      dataRisoluzione: null,
    });
    await problemaRepository.createStorico(idProblema, Stato.Segnalato, idUtente);

    const aggiornato = await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);
    return problemaConverter.toDto(aggiornato);
  }

  async autoassegnaProblema(
    idCasa: string,
    idProblema: string,
    idUtente: string,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    await problemaRepository.updateProblema(idProblema, {
      assegnatario: idUtente,
      stato: Stato.Assegnato,
      dataRisoluzione: null,
    });
    await problemaRepository.createStorico(idProblema, Stato.Assegnato, idUtente);

    const aggiornato = await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);
    return problemaConverter.toDto(aggiornato);
  }

  async assegnaProblema(
    idCasa: string,
    idProblema: string,
    dto: AssegnaProblemaDto,
    idUtente: string,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    const assegnatario = dto.idUtente ?? null;
    const stato = assegnatario ? Stato.Assegnato : Stato.Segnalato;

    await problemaRepository.updateProblema(idProblema, {
      assegnatario,
      stato,
      dataRisoluzione: null,
    });
    await problemaRepository.createStorico(idProblema, stato, idUtente);

    const aggiornato = await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);
    return problemaConverter.toDto(aggiornato);
  }

  async aggiornaStato(
    idCasa: string,
    idProblema: string,
    dto: AggiornaStatoDto,
    idUtente: string,
  ): Promise<ProblemaResponseDto> {
    await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);

    const dataRisoluzione = dto.stato === Stato.Risolto ? new Date() : null;

    await problemaRepository.updateProblema(idProblema, {
      stato: dto.stato,
      dataRisoluzione,
    });
    await problemaRepository.createStorico(idProblema, dto.stato, idUtente);

    const aggiornato = await problemaRepository.findProblemaByIdOrThrow(idCasa, idProblema);
    return problemaConverter.toDto(aggiornato);
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
