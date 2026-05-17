import {
  CreaTurnoDto,
  ModificaTurnoDto,
  AssegnaTurnoDto,
  TurnoResponseDto,
} from "../dto/TurnoDto";
import { TurnoConverter } from "../dto/converter/TurnoConverter";
import {
  TurnoConAssegnatario,
  TurnoRepository,
} from "../repository/TurnoRepository";
import { CasaRepository } from "../repository/CasaRepository";

const turnoConverter = new TurnoConverter();
const turnoRepository = new TurnoRepository();
const casaRepository = new CasaRepository();

function shuffleTurni(ids: string[]): string[] {
  const copy = [...ids];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
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

export class TurnoService {
  async creaTurno(
    idCasa: string,
    dto: CreaTurnoDto,
  ): Promise<TurnoResponseDto> {
    const membriIds = await casaRepository.getMembriCasaIds(idCasa);

    const altriIds = membriIds.filter((id: string) => id !== dto.assegnatario);

    const idsRotazione = [dto.assegnatario, ...shuffleTurni(altriIds)];

    const turno = await turnoRepository.createTurno({
      idCasa,
      task: dto.task,
      rotazioneAttiva: dto.rotazioneTurno,
      assegnatarioCorrente: dto.assegnatario,
      ordineRotazione: idsRotazione,
      indiceRotazioneCorrente: 0,
    });

    return turnoConverter.toDto(turno);
  }

  async getAllTurni(idCasa: string): Promise<TurnoResponseDto[]> {
    const turni = await turnoRepository.findTurniByCasa(idCasa);

    return turni.map((t: TurnoConAssegnatario) => turnoConverter.toDto(t));
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
  ): Promise<TurnoResponseDto> {

    return turnoConverter.toDto(turno);
  }

  async eliminaTurno(idCasa: string, idTurno: string): Promise<void> {}

  async assegnaTurno(
    idCasa: string,
    idTurno: string,
    dto: AssegnaTurnoDto,
  ): Promise<TurnoResponseDto> {

    return turnoConverter.toDto(turno);
  }

  async toggleRotazioneTurni(
    idCasa: string,
    idTurno: string,
  ): Promise<TurnoResponseDto> {

    return turnoConverter.toDto(turno);
  }

  async completaTurno(
    idCasa: string,
    idTurno: string,
  ): Promise<TurnoResponseDto> {

    return turnoConverter.toDto(turno);
  }
}
