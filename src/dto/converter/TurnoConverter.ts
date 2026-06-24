import { TurnoListItemDto, TurnoResponseDto } from "../TurnoDto";

interface TurnoForDto {
  id: string;
  task: string;
  cadenzaGiorni?: number | null;
  rotazioneAttiva: boolean;
  assegnatarioCorrente?: string | null;
  assegnatarioCorrenteRel?: { id: string; username: string } | null;
  idCreatore?: string | null;
  idCreatoreRel?: { id: string; username: string } | null;
  ordineRotazione?: string[] | null;
  indiceRotazioneCorrente?: number | null;
  dataUltimaPulizia?: Date | null;
  dataCreazione: Date;
}

function calcolaProssimaData(riferimento: Date, cadenzaGiorni: number): Date {
  const d = new Date(riferimento);
  d.setDate(d.getDate() + cadenzaGiorni);
  return d;
}

export class TurnoConverter {
  toListItemDto(turno: TurnoForDto): TurnoListItemDto {
    const cadenzaGiorni =
      typeof turno.cadenzaGiorni === "number" && turno.cadenzaGiorni > 0
        ? turno.cadenzaGiorni
        : 1;
    const riferimento: Date = turno.dataUltimaPulizia ?? turno.dataCreazione;
    const dataProssima = calcolaProssimaData(riferimento, cadenzaGiorni);
    const assegnatarioRel = turno.assegnatarioCorrenteRel;

    return {
      id: turno.id,
      task: turno.task,
      assegnatario: {
        id: assegnatarioRel?.id ?? turno.assegnatarioCorrente ?? "",
        username: assegnatarioRel?.username ?? "",
      },
      dataProssimaPulizia: dataProssima.toISOString(),
    };
  }

  toDto(turno: TurnoForDto): TurnoResponseDto {
    const ordineRotazione = Array.isArray(turno.ordineRotazione)
      ? turno.ordineRotazione
      : [];
    const indiceRotazione =
      typeof turno.indiceRotazioneCorrente === "number"
        ? turno.indiceRotazioneCorrente
        : 0;
    const cadenzaGiorni =
      typeof turno.cadenzaGiorni === "number" && turno.cadenzaGiorni > 0
        ? turno.cadenzaGiorni
        : 1;
    const riferimento: Date = turno.dataUltimaPulizia ?? turno.dataCreazione;
    const dataProssima = calcolaProssimaData(riferimento, cadenzaGiorni);
    const assegnatarioRel = turno.assegnatarioCorrenteRel;
    const creatoreRel = turno.idCreatoreRel;

    return {
      id: turno.id,
      task: turno.task,
      cadenzaGiorni,
      rotazioneAttiva: turno.rotazioneAttiva,
      assegnatario: {
        id: assegnatarioRel?.id ?? turno.assegnatarioCorrente ?? "",
        username: assegnatarioRel?.username ?? "",
      },
      creatore: {
        id: creatoreRel?.id ?? turno.idCreatore ?? "",
        username: creatoreRel?.username ?? "",
      },
      ordineRotazione,
      indiceRotazioneCorrente: indiceRotazione,
      dataUltimaPulizia: turno.dataUltimaPulizia?.toISOString() ?? null,
      dataProssimaPulizia: dataProssima.toISOString(),
      dataCreazione: turno.dataCreazione.toISOString(),
    };
  }
}
