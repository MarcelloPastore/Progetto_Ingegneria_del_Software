import { TurnoResponseDto } from "../TurnoDto";

interface OrdineRotazioneSerialized {
  cadenza: number;
  ids: string[];
}

function parseOrdineRotazione(raw: string): OrdineRotazioneSerialized {
  try {
    const parsed = JSON.parse(raw);
    if (
      parsed &&
      typeof parsed.cadenza === "number" &&
      Array.isArray(parsed.ids)
    ) {
      return parsed as OrdineRotazioneSerialized;
    }
  } catch {
    // fallthrough
  }
  return { cadenza: 1, ids: [] };
}

function parseIndice(raw: string): number {
  const n = parseInt(raw, 10);
  return isNaN(n) ? 0 : n;
}

function calcolaProssimaData(riferimento: Date, cadenzaGiorni: number): Date {
  const d = new Date(riferimento);
  d.setDate(d.getDate() + cadenzaGiorni);
  return d;
}

// ─── CONVERTER ────────────────────────────────────────────────────────────────

export class TurnoConverter {
  toDto(turno: any): TurnoResponseDto {
    const { cadenza, ids } = parseOrdineRotazione(turno.ordineRotazione);
    const indice = parseIndice(turno.indiceRotazioneCorrente);
    const riferimento: Date = turno.dataUltimaPulizia ?? turno.dataCreazione;
    const dataProssima = calcolaProssimaData(riferimento, cadenza);

    return {
      id: turno.id,
      task: turno.task,
      cadenzaGiorni: cadenza,
      rotazioneAttiva: turno.rotazioneAttiva,
      assegnatario: {
        id: turno.assegnatarioCorrente.id,
        username: turno.assegnatarioCorrente.username,
      },
      ordineRotazione: ids,
      indiceRotazioneCorrente: indice,
      dataUltimaPulizia: turno.dataUltimaPulizia?.toISOString() ?? null,
      dataProssimaPulizia: dataProssima.toISOString(),
      dataCreazione: turno.dataCreazione.toISOString(),
    };
  }
}
