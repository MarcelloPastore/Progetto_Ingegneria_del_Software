import { Ruolo } from "@prisma/client";
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
import { SpesaConverter } from "../dto/converter/SpesaConverter";
import { CasaRepository } from "../repository/CasaRepository";
import { ConflictError, ForbiddenError } from "../errors/httpErrors";

const spesaRepository = new SpesaRepository();
const spesaConverter = new SpesaConverter();
const casaRepository = new CasaRepository();

function ensurePartecipantiValidi(
  partecipanti: string[],
  ownerId: string,
): string[] {
  const unique = new Set(partecipanti);

  if (unique.size !== partecipanti.length) {
    throw new ConflictError("I partecipanti non possono essere duplicati");
  }

  if (!unique.has(ownerId)) {
    throw new ConflictError("I partecipanti devono includere l'owner");
  }

  return partecipanti;
}

function ensureAnticipataDaInPartecipanti(
  anticipataDa: string | null | undefined,
  partecipanti: string[],
): void {
  if (anticipataDa && !partecipanti.includes(anticipataDa)) {
    throw new ConflictError(
      "L'anticipatario deve essere presente tra i partecipanti",
    );
  }
}

type ScadenzaUpdate = {
  nome: string;
  descrizione: string;
  dataScadenza: Date;
  isRicorrente: boolean;
  cadenzaGiorni?: number | null;
};

function buildScadenzaUpdate(
  dto: ModificaSpesaDto,
  spesa: SpesaConRelazioni,
  descrizione: string,
): ScadenzaUpdate | undefined {
  if (dto.dataScadenza) {
    return {
      nome: `Spesa: ${descrizione}`,
      descrizione,
      dataScadenza: new Date(dto.dataScadenza),
      isRicorrente:
        dto.isRicorrente ?? spesa.scadenzaRel?.isRicorrente ?? false,
      cadenzaGiorni:
        dto.cadenzaGiorni ?? spesa.scadenzaRel?.cadenzaGiorni ?? null,
    };
  }

  if (dto.isRicorrente === undefined && dto.cadenzaGiorni === undefined) {
    return undefined;
  }

  if (!spesa.scadenzaRel) {
    return undefined;
  }

  return {
    nome: `Spesa: ${descrizione}`,
    descrizione,
    dataScadenza: spesa.scadenzaRel.dataScadenza,
    isRicorrente: dto.isRicorrente ?? spesa.scadenzaRel.isRicorrente,
    cadenzaGiorni: dto.cadenzaGiorni ?? spesa.scadenzaRel.cadenzaGiorni ?? null,
  };
}

function buildQuoteData(
  partecipanti: string[],
  importo: number,
  anticipataDa?: string | null,
): Array<{ idUtente: string; quota: number; dataPagamento?: Date }> {
  const totaleCentesimi = Math.round(importo * 100);
  const quotaBase = Math.floor(totaleCentesimi / partecipanti.length);
  const resto = totaleCentesimi - quotaBase * partecipanti.length;

  return partecipanti.map((idUtente, index) => {
    const quotaCentesimi = quotaBase + (index < resto ? 1 : 0);
    return {
      idUtente,
      quota: quotaCentesimi / 100,
      ...(anticipataDa === idUtente ? { dataPagamento: new Date() } : {}),
    };
  });
}

function hasPagamentiNonAnticipatari(spesa: SpesaConRelazioni): boolean {
  const anticipataDa = spesa.anticipataDa ?? null;
  const quote = Array.isArray(spesa.quote) ? spesa.quote : [];

  return quote.some(
    (q) =>
      q.dataPagamento && (anticipataDa ? q.idUtente !== anticipataDa : true),
  );
}

export class SpesaService {
  private async assertIdCreatoreSpesa(
    idCasa: string,
    idSpesa: string,
    idUtente: string,
  ): Promise<SpesaConRelazioni> {
    const spesa = await spesaRepository.findSpesaByIdOrThrow(idCasa, idSpesa);

    if (spesa.owner !== idUtente) {
      throw new ForbiddenError(
        "Solo l'idCreatore della spesa la puo modificare o eliminare",
      );
    }

    return spesa;
  }

  async getAllSpese(idCasa: string): Promise<SpesaResponseDto[]> {
    const spese = await spesaRepository.findSpeseByCasa(idCasa);

    return spese.map((spesa) => spesaConverter.toSpesaDto(spesa));
  }

  async getSpesa(idCasa: string, idSpesa: string): Promise<SpesaResponseDto> {
    const spesa = await spesaRepository.findSpesaByIdOrThrow(idCasa, idSpesa);

    return spesaConverter.toSpesaDto(spesa);
  }

  async addSpesa(
    idCasa: string,
    dto: CreaSpesaDto,
    idUtente: string,
  ): Promise<SpesaResponseDto> {
    const partecipanti = ensurePartecipantiValidi(dto.partecipanti, idUtente);
    const anticipataDa = dto.anticipataDa ?? null;
    if (anticipataDa !== null && anticipataDa !== idUtente) {
      throw new ConflictError(
        "L'anticipatario deve coincidere con l'utente autenticato oppure essere null",
      );
    }
    ensureAnticipataDaInPartecipanti(anticipataDa, partecipanti);

    const quote = buildQuoteData(partecipanti, dto.importo, anticipataDa);
    const scadenza = dto.dataScadenza
      ? {
          nome: `Spesa: ${dto.descrizione}`,
          descrizione: dto.descrizione,
          dataScadenza: new Date(dto.dataScadenza),
          isRicorrente: dto.isRicorrente ?? false,
          cadenzaGiorni: dto.cadenzaGiorni ?? null,
        }
      : undefined;

    const spesa = await spesaRepository.createSpesa({
      idCasa,
      descrizione: dto.descrizione,
      importo: dto.importo,
      owner: idUtente,
      anticipataDa,
      partecipanti,
      scadenza,
      quote,
    });

    return spesaConverter.toSpesaDto(spesa);
  }

  async updateSpesa(
    idCasa: string,
    idSpesa: string,
    dto: ModificaSpesaDto,
    idUtente: string,
  ): Promise<SpesaResponseDto> {
    const spesa = await this.assertIdCreatoreSpesa(idCasa, idSpesa, idUtente);

    if (hasPagamentiNonAnticipatari(spesa)) {
      throw new ConflictError(
        "Non puoi modificare una spesa con pagamenti gia effettuati",
      );
    }

    if (dto.anticipataDa !== undefined && dto.anticipataDa !== null) {
      throw new ConflictError(
        "Puoi solo azzerare l'anticipatario impostando il valore a null",
      );
    }

    const partecipanti = dto.partecipanti
      ? ensurePartecipantiValidi(dto.partecipanti, spesa.owner)
      : spesa.partecipanti;
    const anticipataDa = dto.anticipataDa === null ? null : spesa.anticipataDa;
    ensureAnticipataDaInPartecipanti(anticipataDa, partecipanti);

    const importo = dto.importo ?? spesa.importo;
    const descrizione = dto.descrizione ?? spesa.descrizione;

    const shouldRecomputeQuotes =
      dto.importo !== undefined ||
      dto.partecipanti !== undefined ||
      dto.anticipataDa !== undefined;
    const quote = shouldRecomputeQuotes
      ? buildQuoteData(partecipanti, importo, anticipataDa ?? null)
      : undefined;

    const scadenza = buildScadenzaUpdate(dto, spesa, descrizione);

    const aggiornamento = await spesaRepository.updateSpesa(
      idCasa,
      idSpesa,
      {
        ...(dto.descrizione !== undefined && { descrizione: dto.descrizione }),
        ...(dto.importo !== undefined && { importo: dto.importo }),
        ...(dto.partecipanti !== undefined && { partecipanti }),
        ...(dto.anticipataDa !== undefined && {
          anticipataDa: dto.anticipataDa,
        }),
      },
      quote,
      scadenza,
    );

    return spesaConverter.toSpesaDto(aggiornamento);
  }

  async deleteSpesa(
    idCasa: string,
    idSpesa: string,
    idUtente: string,
  ): Promise<void> {
    const membro = await casaRepository.findMembroCasaByCasaAndUtenteOrThrow(
      idCasa,
      idUtente,
    );
    const isAdmin =
      membro.ruolo === Ruolo.HomeAdmin || membro.ruolo === Ruolo.SysAdmin;
    const spesa = isAdmin
      ? await spesaRepository.findSpesaByIdOrThrow(idCasa, idSpesa)
      : await this.assertIdCreatoreSpesa(idCasa, idSpesa, idUtente);

    if (!isAdmin && hasPagamentiNonAnticipatari(spesa)) {
      throw new ConflictError(
        "Non puoi eliminare una spesa con pagamenti gia effettuati",
      );
    }

    await spesaRepository.deleteSpesa(idCasa, idSpesa, spesa.idScadenza);
  }

  async getDivisioneSpese(
    idCasa: string,
    idSpesa: string,
  ): Promise<QuotaSpesaDto[]> {
    const quote = await spesaRepository.findQuoteBySpesa(idCasa, idSpesa);

    return quote.map((q) => spesaConverter.toQuotaDto(q));
  }

  async pagaQuota(
    idCasa: string,
    idSpesa: string,
    idQuota: string,
    idUtente: string,
  ): Promise<QuotaSpesaDto> {
    const quota = await spesaRepository.findQuoteByIdOrThrow(
      idCasa,
      idSpesa,
      idQuota,
    );

    if (quota.idUtente !== idUtente) {
      throw new ForbiddenError("Solo il debitore puo pagare la quota");
    }

    if (quota.dataPagamento) {
      throw new ConflictError("Quota gia saldata");
    }

    const aggiornata = await spesaRepository.markQuotaPagata(quota.id);

    return spesaConverter.toQuotaDto(aggiornata);
  }

  async getQuota(
    idCasa: string,
    idSpesa: string,
    idQuota: string,
    idUtente: string,
  ): Promise<QuotaSpesaDto> {
    const quota = await spesaRepository.findQuoteByIdOrThrow(
      idCasa,
      idSpesa,
      idQuota,
    );

    if (quota.idUtente !== idUtente) {
      throw new ForbiddenError("Non puoi visualizzare questa quota");
    }

    return spesaConverter.toQuotaDto(quota);
  }

  async pareggiaConti(
    idCasa: string,
    idUtente: string,
    dto: PareggiaContiDto,
  ): Promise<void> {
    await spesaRepository.saldaQuoteVersoCreditori(
      idCasa,
      idUtente,
      dto.idUtentiCreditori,
    );
  }

  async getSaldo(idCasa: string, idUtente: string): Promise<SaldoResponseDto> {
    const credito = await spesaRepository.sumCredito(idCasa, idUtente);
    const debito = await spesaRepository.sumDebito(idCasa, idUtente);

    return { saldo: credito - debito };
  }

  async getCredito(
    idCasa: string,
    idUtente: string,
  ): Promise<CreditoResponseDto> {
    const credito = await spesaRepository.sumCredito(idCasa, idUtente);

    return { credito };
  }

  async getDebito(
    idCasa: string,
    idUtente: string,
  ): Promise<DebitoResponseDto> {
    const debito = await spesaRepository.sumDebito(idCasa, idUtente);

    return { debito };
  }

  async getCreditoVersoUtente(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<CreditoResponseDto> {
    const credito = await spesaRepository.sumCreditoVersoUtente(
      idCasa,
      idUtente,
      idInquilino,
    );

    return { credito };
  }

  async getDebitoVersoUtente(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<DebitoResponseDto> {
    const debito = await spesaRepository.sumDebitoVersoUtente(
      idCasa,
      idUtente,
      idInquilino,
    );

    return { debito };
  }
}
