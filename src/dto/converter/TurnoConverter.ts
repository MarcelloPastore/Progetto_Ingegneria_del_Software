import { TurnoResponseDto } from "../TurnoDto";

function calcolaProssimaData(riferimento: Date, cadenzaGiorni: number): Date {
  const d = new Date(riferimento);
  d.setDate(d.getDate() + cadenzaGiorni);
  return d;
}

export class TurnoConverter {
  toDto(turno: any): TurnoResponseDto {
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

    return {
      id: turno.id,
      task: turno.task,
      cadenzaGiorni,
      rotazioneAttiva: turno.rotazioneAttiva,
      assegnatario: {
        id: assegnatarioRel?.id ?? turno.assegnatarioCorrente ?? "",
        username: assegnatarioRel?.username ?? "",
      },
      ordineRotazione,
      indiceRotazioneCorrente: indiceRotazione,
      dataUltimaPulizia: turno.dataUltimaPulizia?.toISOString() ?? null,
      dataProssimaPulizia: dataProssima.toISOString(),
      dataCreazione: turno.dataCreazione.toISOString(),
    };
  }
}
