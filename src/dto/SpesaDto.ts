import { z } from "zod";
import { AssegnatarioInfoSchema } from "./AssegnatarioDto";

const isoDateString = z
  .string()
  .refine((value) => !Number.isNaN(Date.parse(value)), {
    message: "Data non valida",
  });
const isoDateTimeString = z
  .string()
  .refine((value) => !Number.isNaN(Date.parse(value)), {
    message: "Data/ora non valida",
  });

export const CreaSpesaSchema = z
  .object({
    descrizione: z.string().min(1, "Campo obbligatorio"),
    importo: z.number().positive("Importo deve essere positivo"),
    dataScadenza: isoDateString.optional(),
    partecipanti: z.array(z.string().min(1)).min(1, "Almeno un partecipante"),
    anticipataDa: z.string().min(1).optional(),
    isRicorrente: z.boolean().default(false),
    cadenzaGiorni: z.number().int().positive().optional(),
  })
  .superRefine((data, ctx) => {
    if (data.dataScadenza && data.isRicorrente && !data.cadenzaGiorni) {
      ctx.addIssue({
        code: "custom",
        path: ["cadenzaGiorni"],
        message: "La frequenza è obbligatoria per spese ricorrenti",
      });
    }
  });
export type CreaSpesaDto = z.infer<typeof CreaSpesaSchema>;

export const ModificaSpesaSchema = z
  .object({
    descrizione: z.string().min(1).optional(),
    importo: z.number().positive().optional(),
    dataScadenza: isoDateString.optional(),
    partecipanti: z.array(z.string().min(1)).min(1).optional(),
    anticipataDa: z.string().min(1).nullable().optional(),
    isRicorrente: z.boolean().optional(),
    cadenzaGiorni: z.number().int().positive().optional(),
  })
  .superRefine((data, ctx) => {
    if (
      data.dataScadenza &&
      data.isRicorrente === true &&
      !data.cadenzaGiorni
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["cadenzaGiorni"],
        message: "La frequenza è obbligatoria per spese ricorrenti",
      });
    }
  });
export type ModificaSpesaDto = z.infer<typeof ModificaSpesaSchema>;

export const PareggiaContiSchema = z.object({
  idUtentiCreditori: z
    .array(z.string().min(1))
    .min(1, "Almeno un creditore")
    .describe(
      "Pareggia tutti i debiti del debitore autenticato verso uno o piu coinquilini",
    ),
});
export type PareggiaContiDto = z.infer<typeof PareggiaContiSchema>;

export const SpesaInfoSchema = z.object({
  id: z.string(),
  descrizione: z.string(),
  importo: z.number(),
  anticipataDa: AssegnatarioInfoSchema.nullable(),
});
export type SpesaInfoDto = z.infer<typeof SpesaInfoSchema>;

export const QuotaSpesaSchema = z.object({
  id: z.string(),
  quota: z.number(),
  dataPagamento: isoDateTimeString.nullable(),
  utente: AssegnatarioInfoSchema,
  spesa: SpesaInfoSchema,
});
export type QuotaSpesaDto = z.infer<typeof QuotaSpesaSchema>;

export const PartecipanteSaldoSchema = z.object({
  utente: AssegnatarioInfoSchema,
  saldato: z.boolean(),
});
export type PartecipanteSaldoDto = z.infer<typeof PartecipanteSaldoSchema>;

export const SpesaResponseSchema = z.object({
  id: z.string(),
  descrizione: z.string(),
  importo: z.number(),
  dataCreazione: isoDateTimeString,
  dataScadenza: isoDateString.nullable(),
  isRicorrente: z.boolean(),
  cadenzaMesi: z.number().int().positive().nullable(),
  idScadenza: z.string().nullable(),
  owner: AssegnatarioInfoSchema,
  anticipataDa: AssegnatarioInfoSchema.nullable(),
  partecipanti: z.array(PartecipanteSaldoSchema),
});
export type SpesaResponseDto = z.infer<typeof SpesaResponseSchema>;

export const PareggioContiResponseSchema = z.object({
  quoteSaldate: z.number().int(),
  nuovoSaldo: z.number(),
});
export type PareggioContiResponseDto = z.infer<
  typeof PareggioContiResponseSchema
>;

export const SaldoResponseSchema = z.object({ saldo: z.number() });
export type SaldoResponseDto = z.infer<typeof SaldoResponseSchema>;

export const CreditoResponseSchema = z.object({ credito: z.number() });
export type CreditoResponseDto = z.infer<typeof CreditoResponseSchema>;

export const DebitoResponseSchema = z.object({ debito: z.number() });
export type DebitoResponseDto = z.infer<typeof DebitoResponseSchema>;

export const SpesaListItemSchema = z.object({
  descrizione: z.string(),
  dataCreazione: isoDateTimeString,
  anticipataDa: AssegnatarioInfoSchema.nullable(),
  importoTotale: z.number(),
});
export type SpesaListItemDto = z.infer<typeof SpesaListItemSchema>;
