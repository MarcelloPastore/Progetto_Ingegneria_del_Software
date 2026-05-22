import {
  QuotaSpesaDto,
  SpesaResponseDto,
} from "../SpesaDto";

interface AssegnatarioInfo {
  id: string;
  username: string;
}

interface ScadenzaInfo {
  dataScadenza: Date;
  isRicorrente: boolean;
  cadenzaGiorni?: number | null;
}

interface SpesaForDto {
  id: string;
  descrizione: string;
  importo: number;
  dataCreazione: Date;
  owner?: string | null;
  ownerRel?: AssegnatarioInfo | null;
  anticipataDa?: string | null;
  anticipataDaRel?: AssegnatarioInfo | null;
  partecipanti?: string[] | null;
  partecipantiRel?: AssegnatarioInfo[] | null;
  scadenzaRel?: ScadenzaInfo | null;
  quote?: QuotaForDto[] | null;
}

interface QuotaForDto {
  id: string;
  quota: number;
  dataPagamento?: Date | null;
  idUtente?: string | null;
  utenteRel?: AssegnatarioInfo | null;
}

function toDateOnlyString(value?: Date | null): string | null {
  if (!value) {
    return null;
  }
  return value.toISOString().split("T")[0];
}

function toCadenzaMesi(cadenzaGiorni?: number | null): number | null {
  if (!cadenzaGiorni || cadenzaGiorni <= 0) {
    return null;
  }
  return Math.max(1, Math.round(cadenzaGiorni / 30));
}

function toAssegnatario(
  rel?: AssegnatarioInfo | null,
  fallbackId?: string | null,
): AssegnatarioInfo {
  return {
    id: rel?.id ?? fallbackId ?? "",
    username: rel?.username ?? "",
  };
}

export class SpesaConverter {
  toQuotaDto(quota: QuotaForDto): QuotaSpesaDto {
    return {
      id: quota.id,
      quota: quota.quota,
      dataPagamento: quota.dataPagamento?.toISOString() ?? null,
      utente: toAssegnatario(quota.utenteRel, quota.idUtente),
    };
  }

  toSpesaDto(spesa: SpesaForDto): SpesaResponseDto {
    const scadenza = spesa.scadenzaRel;

    return {
      id: spesa.id,
      descrizione: spesa.descrizione,
      importo: spesa.importo,
      dataCreazione: spesa.dataCreazione.toISOString(),
      dataScadenza: toDateOnlyString(scadenza?.dataScadenza),
      isRicorrente: scadenza?.isRicorrente ?? false,
      cadenzaMesi: toCadenzaMesi(scadenza?.cadenzaGiorni),
      owner: toAssegnatario(spesa.ownerRel, spesa.owner),
      anticipataDa: spesa.anticipataDa
        ? toAssegnatario(spesa.anticipataDaRel, spesa.anticipataDa)
        : null,
      partecipanti: Array.isArray(spesa.partecipantiRel)
        ? spesa.partecipantiRel.map((p) => toAssegnatario(p, p.id))
        : (spesa.partecipanti ?? []).map((id) => toAssegnatario(null, id)),
    };
  }
}
