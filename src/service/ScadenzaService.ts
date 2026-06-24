import { Ruolo } from "@prisma/client";
import {
  CreaScadenzaDto,
  ModificaScadenzaDto,
  AggiornaRicorrenzaDto,
  ScadenzaResponseDto,
} from "../dto/ScadenzaDto";
import {
  ScadenzaBase,
  ScadenzaRepository,
} from "../repository/ScadenzaRepository";
import { CasaRepository } from "../repository/CasaRepository";
import { ConflictError, ForbiddenError } from "../errors/httpErrors";

const scadenzaRepository = new ScadenzaRepository();
const casaRepository = new CasaRepository();

function toDto(scadenza: ScadenzaBase): ScadenzaResponseDto {
  return {
    id: scadenza.id,
    nome: scadenza.nome,
    descrizione: scadenza.descrizione,
    dataScadenza: scadenza.dataScadenza,
    isRicorrente: scadenza.isRicorrente,
    cadenzaGiorni: scadenza.cadenzaGiorni ?? null,
    idCasa: scadenza.idCasa,
    dataCreazione: scadenza.dataCreazione,
    idCreatore: scadenza.idCreatore ?? null,
  };
}

function assertRicorrenzaValida(
  isRicorrente: boolean,
  cadenzaGiorni?: number | null,
): void {
  if (isRicorrente && !cadenzaGiorni) {
    throw new ConflictError(
      "La cadenza e obbligatoria per scadenze ricorrenti",
    );
  }
}

export class ScadenzaService {
  async getAllScadenze(idCasa: string): Promise<ScadenzaResponseDto[]> {
    const scadenze = await scadenzaRepository.findScadenzeByCasa(idCasa);

    return scadenze.map((s) => toDto(s));
  }

  async getScadenza(
    idCasa: string,
    idScadenza: string,
  ): Promise<ScadenzaResponseDto> {
    const scadenza = await scadenzaRepository.findScadenzaByIdOrThrow(
      idCasa,
      idScadenza,
    );

    return toDto(scadenza);
  }

  async creaScadenza(
    idCasa: string,
    dto: CreaScadenzaDto,
    idCreatore: string,
  ): Promise<ScadenzaResponseDto> {
    const isRicorrente = dto.isRicorrente ?? false;
    const cadenzaGiorni = isRicorrente ? (dto.cadenzaGiorni ?? null) : null;
    assertRicorrenzaValida(isRicorrente, cadenzaGiorni);

    const scadenza = await scadenzaRepository.createScadenza({
      idCasa,
      nome: dto.nome,
      descrizione: dto.descrizione ?? "",
      dataScadenza: dto.dataScadenza,
      isRicorrente,
      cadenzaGiorni,
      idCreatore,
    });

    return toDto(scadenza);
  }

  async modificaScadenza(
    idCasa: string,
    idScadenza: string,
    dto: ModificaScadenzaDto,
    idUtente: string,
    ruoloCasa?: Ruolo,
  ): Promise<ScadenzaResponseDto> {
    const esistente = await scadenzaRepository.findScadenzaByIdOrThrow(
      idCasa,
      idScadenza,
    );

    if (
      esistente.idCreatore !== idUtente &&
      ruoloCasa !== Ruolo.SysAdmin
    ) {
      throw new ForbiddenError(
        "Solo chi ha creato la scadenza può modificarla",
      );
    }

    const scadenza = await scadenzaRepository.updateScadenza(idScadenza, {
      ...(dto.nome !== undefined && { nome: dto.nome }),
      ...(dto.descrizione !== undefined && { descrizione: dto.descrizione }),
      ...(dto.dataScadenza !== undefined && {
        dataScadenza: dto.dataScadenza,
      }),
    });

    return toDto(scadenza);
  }

  async eliminaScadenza(
    idCasa: string,
    idScadenza: string,
    idUtente: string,
  ): Promise<void> {
    const scadenza = await scadenzaRepository.findScadenzaByIdOrThrow(
      idCasa,
      idScadenza,
    );
    const membro = await casaRepository.findMembroCasaByCasaAndUtenteOrThrow(
      idCasa,
      idUtente,
    );
    const isAdmin =
      membro.ruolo === Ruolo.HomeAdmin || membro.ruolo === Ruolo.SysAdmin;
    if (!isAdmin && scadenza.idCreatore !== idUtente) {
      throw new ForbiddenError(
        "Solo chi ha creato la scadenza o un HomeAdmin può eliminarla",
      );
    }
    await scadenzaRepository.deleteScadenza(idCasa, idScadenza);
  }

  async aggiornaRicorrenza(
    idCasa: string,
    idScadenza: string,
    dto: AggiornaRicorrenzaDto,
  ): Promise<ScadenzaResponseDto> {
    const scadenza = await scadenzaRepository.findScadenzaByIdOrThrow(
      idCasa,
      idScadenza,
    );
    const isRicorrente = dto.isRicorrente;
    const cadenzaGiorni = isRicorrente
      ? (dto.cadenzaGiorni ?? scadenza.cadenzaGiorni ?? null)
      : null;
    assertRicorrenzaValida(isRicorrente, cadenzaGiorni);

    const aggiornata = await scadenzaRepository.updateScadenza(idScadenza, {
      isRicorrente,
      cadenzaGiorni,
    });

    return toDto(aggiornata);
  }
}
