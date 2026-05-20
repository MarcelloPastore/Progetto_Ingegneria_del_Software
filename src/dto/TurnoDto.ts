import { z } from "zod";
import { AssegnatarioInfoSchema } from "./AssegnatarioDto";

export const CreaTurnoSchema = z.object({
  task: z.string().min(1, "Campo obbligatorio"),
  cadenzaGiorni: z
    .number()
    .int()
    .positive("La cadenza deve essere almeno 1 giorno"),
  assegnatario: z.string().min(1, "ID assegnatario obbligatorio"),
  rotazioneTurno: z.boolean().default(true),
});
export type CreaTurnoDto = z.infer<typeof CreaTurnoSchema>;

export const ModificaTurnoSchema = z.object({
  task: z.string().min(1).optional(),
  cadenzaGiorni: z.number().int().positive().optional(),
  rotazioneTurno: z.boolean().optional(),
});
export type ModificaTurnoDto = z.infer<typeof ModificaTurnoSchema>;

export const AssegnaTurnoSchema = z.object({
  idUtente: z.string().min(1, "ID Utente richiesto"),
});
export type AssegnaTurnoDto = z.infer<typeof AssegnaTurnoSchema>;

export const TurnoResponseSchema = z.object({
  id: z.string(),
  task: z.string(),
  cadenzaGiorni: z.number().int(),
  rotazioneAttiva: z.boolean(),
  assegnatario: AssegnatarioInfoSchema,
  ordineRotazione: z.string().array(),
  indiceRotazioneCorrente: z.number().int(),
  dataUltimaPulizia: z.string().datetime().nullable(),
  dataProssimaPulizia: z.string().datetime(),
  dataCreazione: z.string().datetime(),
});
export type TurnoResponseDto = z.infer<typeof TurnoResponseSchema>;

export const DataTurnoSchema = z.object({
  id: z.string(),
  dataProssimaPuliza: z.string(),
});
export type DataTurnoDto = z.infer<typeof DataTurnoSchema>;
