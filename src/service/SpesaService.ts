import {
  CreaSpesaDto,
  ModificaSpesaDto,
  QuotaSpesaDto,
  SpesaResponseDto,
  SaldoResponseDto,
  CreditoResponseDto,
  DebitoResponseDto,
  PareggiaContiDto,
} from "../dto/SpesaDto";
import {
  SpesaConRelazioni,
  SpesaRepository,
} from "../repository/SpesaRepository";

const spesaRepository = new SpesaRepository();

function toDateOnlyString(value?: Date | null): string | null {
  if (!value) {
    return null;
  }
  return value.toISOString().split("T")[0];
}

function toAssegnatario(
  rel?: { id: string; username: string } | null,
  fallbackId?: string | null,
): { id: string; username: string } {
  return {
    id: rel?.id ?? fallbackId ?? "",
    username: rel?.username ?? "",
  };
}

function toSpesaDto(spesa: SpesaConRelazioni): SpesaResponseDto {
  const scadenza = spesa.scadenzaRel;
  const cadenzaMesi = scadenza?.cadenzaGiorni
    ? Math.max(1, Math.round(scadenza.cadenzaGiorni / 30))
    : null;

  return {
    id: spesa.id,
    descrizione: spesa.descrizione,
    importo: spesa.importo,
    dataCreazione: spesa.dataCreazione.toISOString(),
    dataScadenza: toDateOnlyString(scadenza?.dataScadenza),
    isRicorrente: scadenza?.isRicorrente ?? false,
    cadenzaMesi,
    owner: toAssegnatario(spesa.ownerRel, spesa.owner),
    anticipataDa: spesa.anticipataDa
      ? toAssegnatario(spesa.anticipataDaRel, spesa.anticipataDa)
      : null,
    partecipanti: Array.isArray(spesa.partecipantiRel)
      ? spesa.partecipantiRel.map((p) => toAssegnatario(p, p.id))
      : (spesa.partecipanti ?? []).map((id) => toAssegnatario(null, id)),
  };
}

export class SpesaService {
  async getAllSpese(idCasa: string): Promise<SpesaResponseDto[]> {
    const spese = await spesaRepository.findSpeseByCasa(idCasa);

    return spese.map((s: SpesaConRelazioni) => toSpesaDto(s));
  }

  async getSpesa(
    idCasa: string,
    idSpesa: string,
    idUtente: string,
  ): Promise<SpesaResponseDto> {
    throw new Error("Not implemented");
  }

  async addSpesa(
    idCasa: string,
    dto: CreaSpesaDto,
    idUtente: string,
  ): Promise<SpesaResponseDto> {
    throw new Error("Not implemented");
  }

  async updateSpesa(
    idCasa: string,
    idSpesa: string,
    dto: ModificaSpesaDto,
    idUtente: string,
  ): Promise<SpesaResponseDto> {
    throw new Error("Not implemented");
  }

  async deleteSpesa(
    idCasa: string,
    idSpesa: string,
    idUtente: string,
  ): Promise<void> {
    throw new Error("Not implemented");
  }

  async getDivisioneSpese(
    idCasa: string,
    idSpesa: string,
  ): Promise<QuotaSpesaDto[]> {
    throw new Error("Not implemented");
  }

  async pagaQuota(
    idCasa: string,
    idSpesa: string,
    idQuota: string,
    idUtente: string,
  ): Promise<QuotaSpesaDto> {
    throw new Error("Not implemented");
  }

  async getQuota(
    idCasa: string,
    idSpesa: string,
    idQuota: string,
  ): Promise<QuotaSpesaDto> {
    throw new Error("Not implemented");
  }

  async pareggiaConti(
    idCasa: string,
    idUtente: string,
    dto: PareggiaContiDto,
  ): Promise<void> {
    throw new Error("Not implemented");
  }

  async getSaldo(idCasa: string, idUtente: string): Promise<SaldoResponseDto> {
    throw new Error("Not implemented");
  }

  async getCredito(
    idCasa: string,
    idUtente: string,
  ): Promise<CreditoResponseDto> {
    throw new Error("Not implemented");
  }

  async getDebito(
    idCasa: string,
    idUtente: string,
  ): Promise<DebitoResponseDto> {
    throw new Error("Not implemented");
  }

  async getCreditoVersoUtente(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<CreditoResponseDto> {
    throw new Error("Not implemented");
  }

  async getDebitoVersoUtente(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<DebitoResponseDto> {
    throw new Error("Not implemented");
  }
}
