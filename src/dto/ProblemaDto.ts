import { z } from "zod";
import { AssegnatarioInfoSchema } from "./AssegnatarioDto";

const prioritaValues = ["Urgente", "Media", "Bassa"] as const;
const statoValues = ["Segnalato", "Assegnato", "Risolto"] as const;

const PrioritaSchema = z.enum(prioritaValues);
const StatoSchema = z.enum(statoValues);

const isoDateTimeString = z
  .string()
  .refine((value) => !Number.isNaN(Date.parse(value)), {
    message: "Data/ora non valida",
  });

export const CreaProblemaSchema = z.object({
  nome: z.string().min(1, "Campo obbligatorio"),
  descrizione: z.string().min(1, "Campo obbligatorio"),
  priorita: PrioritaSchema.optional(),
});
export type CreaProblemaDto = z.infer<typeof CreaProblemaSchema>;

export const AssegnaProblemaSchema = z.object({
  idUtente: z.string().min(1, "ID Utente richiesto").nullable(),
});
export type AssegnaProblemaDto = z.infer<typeof AssegnaProblemaSchema>;

export const AggiornaStatoSchema = z.object({
  stato: StatoSchema,
});
export type AggiornaStatoDto = z.infer<typeof AggiornaStatoSchema>;

export const AggiornaPrioritaSchema = z.object({
  priorita: PrioritaSchema,
});
export type AggiornaPrioritaDto = z.infer<typeof AggiornaPrioritaSchema>;

export const ModificaProblemaSchema = z.object({
  nome: z.string().min(1, "Campo obbligatorio").optional(),
  descrizione: z.string().min(1, "Campo obbligatorio").optional(),
  priorita: PrioritaSchema.optional(),
});
export type ModificaProblemaDto = z.infer<typeof ModificaProblemaSchema>;

export const StoricoItemSchema = z.object({
  stato: StatoSchema,
  data: isoDateTimeString,
  utente: z.object({ id: z.string(), username: z.string() }),
});
export type StoricoItemDto = z.infer<typeof StoricoItemSchema>;

export const ProblemaResponseSchema = z.object({
  id: z.string(),
  nome: z.string(),
  descrizione: z.string(),
  priorita: PrioritaSchema,
  stato: StatoSchema,
  segnalataDa: AssegnatarioInfoSchema,
  assegnatario: AssegnatarioInfoSchema.nullable(),
  dataCreazione: isoDateTimeString,
  dataRisoluzione: isoDateTimeString.nullable(),
  storicoStato: z.array(StoricoItemSchema),
});
export type ProblemaResponseDto = z.infer<typeof ProblemaResponseSchema>;

export const ProblemaListItemSchema = z.object({
  id: z.string(),
  nome: z.string(),
  descrizione: z.string(),
  assegnatario: AssegnatarioInfoSchema.nullable(),
  stato: StatoSchema,
  priorita: PrioritaSchema,
});
export type ProblemaListItemDto = z.infer<typeof ProblemaListItemSchema>;
