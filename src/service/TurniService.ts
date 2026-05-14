import { CreaTurnoDto } from "../dto/TurnoDto";
import { prisma } from "../config/db";
import { Ruolo } from "@prisma/client";

export class TurniService {
  static creaTurno(idCasa: string, dto: CreaTurnoDto) {
    // Cercare idCasa nel Db
    // Aggiunta turno con informazioni fornite
  }

  static async getProssimiTurni(idCasa: string): Promise<void> {
    //TODO: Implementare il calcolo dei prossimi turni
  }
}
