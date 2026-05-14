export interface CasaPayload {
  idCasa: string;
}

// - TurnoController -
export interface TurnoPayload extends CasaPayload {
  idTurno: string;
}

// - SpesaController -
export interface SpesaPayload extends CasaPayload {
  idSpesa: string;
}

export interface QuotaPayload extends SpesaPayload {
  idQuota: string;
}

export interface InquilinoPayload extends CasaPayload {
  idInquilino: string;
}
