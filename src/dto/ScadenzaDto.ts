import { z } from "zod";

export const CreaScadenzaDto = z.object({
  nome: z.string().min(1, "Il nome non può essere vuoto."),
  descrizione: z.string().optional().default(""),
  dataScadenza: z.coerce.date(),
  isRicorrente: z.boolean().optional().default(false),
  cadenzaGiorni: z
    .number()
    .int()
    .min(1, "La cadenza deve essere almeno di 1 giorno.")
    .optional(),
});
export type CreaScadenzaDto = z.infer<typeof CreaScadenzaDto>;

export const ModificaScadenzaDto = z.object({
  nome: z.string().min(1, "Il nome non può essere vuoto.").optional(),
  descrizione: z.string().optional(),
  dataScadenza: z.coerce.date().optional(),
});
export type ModificaScadenzaDto = z.infer<typeof ModificaScadenzaDto>;

export const AggiornaRicorrenzaDto = z.object({
  isRicorrente: z.boolean(),
  cadenzaGiorni: z
    .number()
    .int()
    .min(1, "La cadenza deve essere almeno di 1 giorno.")
    .optional(),
});
export type AggiornaRicorrenzaDto = z.infer<typeof AggiornaRicorrenzaDto>;

export const ScadenzaResponseDto = z.object({
  id: z.string(),
  nome: z.string(),
  descrizione: z.string(),
  dataScadenza: z.coerce.date(),
  isRicorrente: z.boolean(),
  cadenzaGiorni: z.number().int().nullable(),
  idCasa: z.string(),
  dataCreazione: z.coerce.date(),
  idCreatore: z.string().nullable(),
});
export type ScadenzaResponseDto = z.infer<typeof ScadenzaResponseDto>;
