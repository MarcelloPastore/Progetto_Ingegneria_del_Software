import {
  CreaSpesaDto,
  ModificaSpesaDto,
  PagaQuotaDto,
  QuotaSpesaDto,
  SpesaDettaglioDto,
  SpesaResponseDto,
  SaldoResponseDto,
  CreditoResponseDto,
  DebitoResponseDto,
  PareggiaContiDto,
} from "../dto/SpesaDto";

export class SpesaService {
  /** @throws NotFoundError */
  async getAllSpese(idCasa: string): Promise<SpesaResponseDto[]> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getSpesa(
    idCasa: string,
    idSpesa: string,
    idUtente: string,
  ): Promise<SpesaDettaglioDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async addSpesa(
    idCasa: string,
    dto: CreaSpesaDto,
    idUtente: string,
  ): Promise<SpesaDettaglioDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError @throws ForbiddenError */
  async updateSpesa(
    idCasa: string,
    idSpesa: string,
    dto: ModificaSpesaDto,
    idUtente: string,
  ): Promise<SpesaDettaglioDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError @throws ForbiddenError */
  async deleteSpesa(
    idCasa: string,
    idSpesa: string,
    idUtente: string,
  ): Promise<void> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getDivisioneSpese(
    idCasa: string,
    idSpesa: string,
  ): Promise<QuotaSpesaDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError @throws ForbiddenError */
  async pagaQuota(
    idCasa: string,
    idSpesa: string,
    idQuota: string,
    dto: PagaQuotaDto,
    idUtente: string,
  ): Promise<QuotaSpesaDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async pareggiaConti(
    idCasa: string,
    idUtente: string,
    dto: PareggiaContiDto,
  ): Promise<void> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getSaldo(idCasa: string, idUtente: string): Promise<SaldoResponseDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getCredito(
    idCasa: string,
    idUtente: string,
  ): Promise<CreditoResponseDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getDebito(
    idCasa: string,
    idUtente: string,
  ): Promise<DebitoResponseDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getCreditoVersoUtente(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<CreditoResponseDto> {
    throw new Error("Not implemented");
  }

  /** @throws NotFoundError */
  async getDebitoVersoUtente(
    idCasa: string,
    idInquilino: string,
    idUtente: string,
  ): Promise<DebitoResponseDto> {
    throw new Error("Not implemented");
  }
}
