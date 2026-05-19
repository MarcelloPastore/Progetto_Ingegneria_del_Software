import { Ruolo } from "@prisma/client";

export interface RegisterData {
  email: string;
  password: string;
  nome: string;
  cognome: string;
  ruolo?: Ruolo; //@TODO togliere ruolo
}

export interface PublicUser {
  id: string;
  email: string;
  nome: string;
  cognome: string;
  ruolo: Ruolo;
}
