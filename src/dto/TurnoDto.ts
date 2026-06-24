import { z } from "zod";
import { AssegnatarioInfoSchema } from "./AssegnatarioDto";

const isoDateTimeString = z
  .string()
  .refine((value) => !Number.isNaN(Date.parse(value)), {
    message: "Data/ora non valida",
  });

export const CreaTurnoSchema = z.object({
  task: z.string().min(1, "Campo obbligatorio"),
  dataTurno: isoDateTimeString,
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
  creatore: AssegnatarioInfoSchema,
  ordineRotazione: z.string().array(),
  indiceRotazioneCorrente: z.number().int(),
  dataUltimaPulizia: isoDateTimeString.nullable(),
  dataProssimaPulizia: isoDateTimeString,
  dataCreazione: isoDateTimeString,
});
export type TurnoResponseDto = z.infer<typeof TurnoResponseSchema>;

export const TurnoListItemSchema = z.object({
  id: z.string(),
  task: z.string(),
  assegnatario: AssegnatarioInfoSchema,
  dataProssimaPulizia: isoDateTimeString,
});
export type TurnoListItemDto = z.infer<typeof TurnoListItemSchema>;

export const DataTurnoSchema = z.object({
  id: z.string(),
  dataProssimaPulizia: isoDateTimeString,
});

export const SaluteCasaSchema = z.object({
  id: z.string(),
  task: z.string(),
  giorniPassati: z.number().int().nonnegative(),
  cadenzaGiorni: z.number().int().positive(),
});
export type SaluteCasaDto = z.infer<typeof SaluteCasaSchema>;
