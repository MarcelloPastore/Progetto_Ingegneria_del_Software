import { QuotaSpesaDto, SpesaResponseDto } from "../SpesaDto";

interface AssegnatarioInfo {
  id: string;
  username: string;
}

interface ScadenzaInfo {
  dataScadenza: Date;
  isRicorrente: boolean;
  cadenzaGiorni?: number | null;
}

interface SpesaInfoForDto {
  id: string;
  descrizione: string;
  importo: number;
  anticipataDa?: string | null;
  anticipataDaRel?: AssegnatarioInfo | null;
}

interface SpesaForDto extends SpesaInfoForDto {
  dataCreazione: Date;
  owner?: string | null;
  ownerRel?: AssegnatarioInfo | null;
  partecipanti?: string[] | null;
  partecipantiRel?: AssegnatarioInfo[] | null;
  scadenzaRel?: ScadenzaInfo | null;
  quote?: QuotaForSpesaDto[] | null;
}

interface QuotaForSpesaDto {
  id: string;
  quota: number;
  dataPagamento?: Date | null;
  idUtente?: string | null;
  utenteRel?: AssegnatarioInfo | null;
}

interface QuotaForDto extends QuotaForSpesaDto {
  spesaRel: SpesaInfoForDto;
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

function toSpesaInfo(spesa: SpesaInfoForDto) {
  return {
    id: spesa.id,
    descrizione: spesa.descrizione,
    importo: spesa.importo,
    anticipataDa: spesa.anticipataDa
      ? toAssegnatario(spesa.anticipataDaRel, spesa.anticipataDa)
      : null,
  };
}

export class SpesaConverter {
  toQuotaDto(quota: QuotaForDto): QuotaSpesaDto {
    return {
      quota: quota.quota,
      dataPagamento: quota.dataPagamento?.toISOString() ?? null,
      utente: toAssegnatario(quota.utenteRel, quota.idUtente),
      spesa: toSpesaInfo(quota.spesaRel),
    };
  }

  toSpesaDto(spesa: SpesaForDto): SpesaResponseDto {
    const scadenza = spesa.scadenzaRel;
    const quote = Array.isArray(spesa.quote) ? spesa.quote : [];
    const partecipantiDaQuote = quote.length
      ? quote.map((q) => ({
          utente: toAssegnatario(q.utenteRel, q.idUtente),
          saldato: Boolean(q.dataPagamento),
        }))
      : null;
    const partecipantiFallback = Array.isArray(spesa.partecipantiRel)
      ? spesa.partecipantiRel.map((p) => ({
          utente: toAssegnatario(p, p.id),
          saldato: false,
        }))
      : (spesa.partecipanti ?? []).map((id) => ({
          utente: toAssegnatario(null, id),
          saldato: false,
        }));

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
      partecipanti: partecipantiDaQuote ?? partecipantiFallback,
    };
  }
}
