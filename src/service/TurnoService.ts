import {
  CreaTurnoDto,
  ModificaTurnoDto,
  AssegnaTurnoDto,
  TurnoListItemDto,
  TurnoResponseDto,
} from "../dto/TurnoDto";
import { TurnoConverter } from "../dto/converter/TurnoConverter";
import {
  TurnoConAssegnatario,
  TurnoRepository,
} from "../repository/TurnoRepository";
import { CasaRepository } from "../repository/CasaRepository";
import { ForbiddenError } from "../errors/httpErrors";
import { randomInt } from "node:crypto";

const turnoConverter = new TurnoConverter();
const turnoRepository = new TurnoRepository();
const casaRepository = new CasaRepository();

function shuffleTurni(ids: string[]): string[] {
  const copy = [...ids];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = randomInt(i + 1);
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

function isToday(isoString: string): boolean {
  const d = new Date(isoString);
  const oggi = new Date();
  return (
    d.getFullYear() === oggi.getFullYear() &&
    d.getMonth() === oggi.getMonth() &&
    d.getDate() === oggi.getDate()
  );
}

function aggiornaOrdineRotazione(
  ordineCorrente: string[],
  membriIds: string[],
): string[] {
  const membriSet = new Set(membriIds);
  const ordineFiltrato = ordineCorrente.filter((id) => membriSet.has(id));
  const presenti = new Set(ordineFiltrato);
  const nuovi = membriIds.filter((id) => !presenti.has(id));

  return [...ordineFiltrato, ...nuovi];
}

export class TurnoService {
  private async assertIdCreatoreTurno(
    idCasa: string,
    idTurno: string,
    idUtente: string,
  ): Promise<TurnoConAssegnatario> {
    const turno = await turnoRepository.findTurnoByIdOrThrow(idCasa, idTurno);

    if (turno.idCreatore !== idUtente) {
      throw new ForbiddenError(
        "Solo l'idCreatore del turno puo modificare o eliminare",
      );
    }

    return turno;
  }

  private async assertAssegnatarioCorrente(
    idCasa: string,
    idTurno: string,
    idUtente: string,
  ): Promise<TurnoConAssegnatario> {
    const turno = await turnoRepository.findTurnoByIdOrThrow(idCasa, idTurno);

    if (turno.assegnatarioCorrente !== idUtente) {
      throw new ForbiddenError(
        "Solo l'assegnatario corrente puo completare il turno",
      );
    }

    return turno;
  }

  async creaTurno(
    idCasa: string,
    dto: CreaTurnoDto,
    idCreatore: string,
  ): Promise<TurnoResponseDto> {
    let idsRotazione = [dto.assegnatario];

    if (dto.rotazioneTurno) {
      const membriIds = await casaRepository.getMembriCasaIds(idCasa);
      const altriIds = membriIds.filter(
        (id: string) => id !== dto.assegnatario,
      );
      idsRotazione = [dto.assegnatario, ...shuffleTurni(altriIds)];
    }

    const turno = await turnoRepository.createTurno({
      idCasa,
      task: dto.task,
      cadenzaGiorni: dto.cadenzaGiorni,
      rotazioneAttiva: dto.rotazioneTurno,
      assegnatarioCorrente: dto.assegnatario,
      ordineRotazione: idsRotazione,
      indiceRotazioneCorrente: 0,
      idCreatore,
    });

    return turnoConverter.toDto(turno);
  }

  async getAllTurni(idCasa: string): Promise<TurnoListItemDto[]> {
    const turni = await turnoRepository.findTurniByCasa(idCasa);

    return turni.map((t: TurnoConAssegnatario) => turnoConverter.toListItemDto(t));
  }

  async getTurniOdierni(idCasa: string): Promise<TurnoResponseDto[]> {
    const turni = await turnoRepository.findTurniByCasa(idCasa);

    return turni
      .map((t: TurnoConAssegnatario) => turnoConverter.toDto(t))
      .filter((dto: TurnoResponseDto) => isToday(dto.dataProssimaPulizia));
  }

  async getTurno(idCasa: string, idTurno: string): Promise<TurnoResponseDto> {
    const turno = await turnoRepository.findTurnoByIdOrThrow(idCasa, idTurno);

    return turnoConverter.toDto(turno);
  }

  async modificaTurno(
    idCasa: string,
    idTurno: string,
    dto: ModificaTurnoDto,
    idUtente: string,
  ): Promise<TurnoResponseDto> {
    const turno = await this.assertIdCreatoreTurno(idCasa, idTurno, idUtente);
    const membriIds = await casaRepository.getMembriCasaIds(idCasa);
    const ordineAggiornato = aggiornaOrdineRotazione(
      turno.ordineRotazione,
      membriIds,
    );

    const aggiornamento = await turnoRepository.updateTurno(idTurno, {
      ...(dto.task !== undefined && { task: dto.task }),
      ...(dto.cadenzaGiorni !== undefined && {
        cadenzaGiorni: dto.cadenzaGiorni,
      }),
      ...(dto.rotazioneTurno !== undefined && {
        rotazioneAttiva: dto.rotazioneTurno,
      }),
      ordineRotazione: ordineAggiornato,
    });

    return turnoConverter.toDto(aggiornamento);
  }

  async eliminaTurno(
    idCasa: string,
    idTurno: string,
    idUtente: string,
  ): Promise<void> {
    await this.assertIdCreatoreTurno(idCasa, idTurno, idUtente);

    await turnoRepository.deleteTurno(idCasa, idTurno);
  }

  async autoassegnaTurno(
    idCasa: string,
    idTurno: string,
    idUtente: string,
  ): Promise<TurnoResponseDto> {
    await turnoRepository.findTurnoByIdOrThrow(idCasa, idTurno);

    const aggiornamento = await turnoRepository.updateTurno(idTurno, {
      assegnatarioCorrente: idUtente,
    });

    return turnoConverter.toDto(aggiornamento);
  }

  async assegnaTurno(
    idCasa: string,
    idTurno: string,
    dto: AssegnaTurnoDto,
  ): Promise<TurnoResponseDto> {
    await turnoRepository.findTurnoByIdOrThrow(idCasa, idTurno);

    const aggiornamento = await turnoRepository.updateTurno(idTurno, {
      assegnatarioCorrente: dto.idUtente,
    });

    return turnoConverter.toDto(aggiornamento);
  }

  async toggleRotazioneTurni(
    idCasa: string,
    idTurno: string,
  ): Promise<TurnoResponseDto> {
    const turno = await turnoRepository.findTurnoByIdOrThrow(idCasa, idTurno);

    const aggiornamento = await turnoRepository.updateTurno(idTurno, {
      rotazioneAttiva: !turno.rotazioneAttiva,
    });

    return turnoConverter.toDto(aggiornamento);
  }

  async completaTurno(
    idCasa: string,
    idTurno: string,
    idUtente: string,
  ): Promise<TurnoResponseDto> {
    const turno = await this.assertAssegnatarioCorrente(
      idCasa,
      idTurno,
      idUtente,
    );
    const ordine = turno.ordineRotazione ?? [];
    const ordineLength = ordine.length;
    const indiceCorrente = turno.indiceRotazioneCorrente ?? 0;

    const indiceProssimo =
      ordineLength === 0 ? indiceCorrente : (indiceCorrente + 1) % ordineLength;
    const assegnatarioProssimo =
      ordineLength === 0 ? turno.assegnatarioCorrente : ordine[indiceProssimo];

    const aggiornamento = await turnoRepository.updateTurno(idTurno, {
      dataUltimaPulizia: new Date(),
      indiceRotazioneCorrente: indiceProssimo,
      assegnatarioCorrente: assegnatarioProssimo,
    });

    return turnoConverter.toDto(aggiornamento);
  }
}
