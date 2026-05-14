import { z } from "zod";

export const CreaTurnoSchema = z.object({
  task: z.string().min(1, "Campo obbligatorio"),
  data: z.iso.datetime(),
  frequenza: z.int32(),
  assegnatario: z.string(),
  rotazioneTurno: z.boolean().default(true),
});
export type CreaTurnoDto = z.infer<typeof CreaTurnoSchema>;

export const ModificaTurnoSchema = z.object({
  descrizione: z.string().optional(),
  dataScadenza: z.iso.datetime().optional(),
});
export type ModificaTurnoDto = z.infer<typeof ModificaTurnoSchema>;

export const AssegnaTurnoSchema = z.object({
  idUtente: z.string().min(1, "ID Utente richiesto"),
});
export type AssegnaTurnoDto = z.infer<typeof AssegnaTurnoSchema>;

export const TurnoResponseSchema = z.object({
  id: z.string(),
  descrizione: z.string().optional(),
  completato: z.boolean().default(false),
});
export type TurnoResponseDto = z.infer<typeof TurnoResponseSchema>;
