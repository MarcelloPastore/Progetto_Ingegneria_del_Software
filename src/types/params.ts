export interface CasaParams {
  idCasa: string;
}

export interface InquilinoParams extends CasaParams {
  idInquilino: string;
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

// - ProblemiController -
export interface ProblemaParams extends CasaParams {
  idProblema: string;
}

// - ScadenzaController -
export interface ScadenzaParams extends CasaParams {
  idScadenza: string;
}

// - UtenteController -
export interface UserParams {
  idUtente: string;
}
