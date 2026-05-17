export interface CasaParams {
  idCasa: string;
}

// - TurnoController -
export interface TurnoParams extends CasaParams {
  idTurno: string;
}

// - SpesaController -
export interface SpesaParams extends CasaParams {
  idSpesa: string;
}

export interface QuotaParams extends SpesaParams {
  idQuota: string;
}

export interface InquilinoParams extends CasaParams {
  idInquilino: string;
}

// - ProblemiController -
export interface ProblemaParams extends CasaParams {
  idProblema: string;
}
