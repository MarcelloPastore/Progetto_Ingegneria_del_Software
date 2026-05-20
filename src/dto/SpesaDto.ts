import { z } from "zod";
import { AssegnatarioInfoSchema } from "./AssegnatarioDto";

export const CreaSpesaSchema = z
  .object({
    descrizione: z.string().min(1, "Campo obbligatorio"),
    importo: z.number().positive("Importo deve essere positivo"),
    dataScadenza: z.string().date().optional(), // data pagamento prevista
    partecipanti: z.array(z.string().min(1)).min(1, "Almeno un partecipante"),
    anticipataDa: z.string().min(1).optional(), // chi ha anticipato il totale
    isRicorrente: z.boolean().default(false), // solo HomeAdmin può attivarlo
    cadenzaMesi: z.number().int().positive().optional(), // obbligatorio se isRicorrente
  })
  .superRefine((data, ctx) => {
    if (data.isRicorrente && !data.cadenzaMesi) {
      ctx.addIssue({
        code: "custom",
        path: ["cadenzaMesi"],
        message: "cadenzaMesi è obbligatorio per spese ricorrenti",
      });
    }
  });
export type CreaSpesaDto = z.infer<typeof CreaSpesaSchema>;

export const ModificaSpesaSchema = z
  .object({
    descrizione: z.string().min(1).optional(),
    importo: z.number().positive().optional(),
    dataScadenza: z.string().date().optional(),
    partecipanti: z.array(z.string().min(1)).min(1).optional(),
    anticipataDa: z.string().min(1).nullable().optional(),
    isRicorrente: z.boolean().optional(),
    cadenzaMesi: z.number().int().positive().optional(),
  })
  .superRefine((data, ctx) => {
    if (data.isRicorrente === true && !data.cadenzaMesi) {
      ctx.addIssue({
        code: "custom",
        path: ["cadenzaMesi"],
        message: "cadenzaMesi è obbligatorio quando si attiva la ricorrenza",
      });
    }
  });
export type ModificaSpesaDto = z.infer<typeof ModificaSpesaSchema>;

export const PagaQuotaSchema = z.object({
  dataPagamento: z.string().datetime().optional(),
});
export type PagaQuotaDto = z.infer<typeof PagaQuotaSchema>;

export const PareggiaContiSchema = z.object({
  idUtentiCreditori: z
    .array(z.string().min(1))
    .optional()
    .describe("Se vuoto o assente: pareggia con tutti i coinquilini"),
});
export type PareggiaContiDto = z.infer<typeof PareggiaContiSchema>;

export const QuotaSpesaSchema = z.object({
  id: z.string(),
  quota: z.number(),
  dataPagamento: z.string().datetime().nullable(),
  utente: AssegnatarioInfoSchema,
});
export type QuotaSpesaDto = z.infer<typeof QuotaSpesaSchema>;

export const SpesaResponseSchema = z.object({
  id: z.string(),
  descrizione: z.string(),
  importo: z.number(),
  dataCreazione: z.string().datetime(),
  dataScadenza: z.string().date().nullable(),
  isRicorrente: z.boolean(),
  cadenzaMesi: z.number().int().positive().nullable(),
  owner: AssegnatarioInfoSchema,
  anticipataDa: AssegnatarioInfoSchema.nullable(),
  partecipanti: z.array(AssegnatarioInfoSchema),
});
export type SpesaResponseDto = z.infer<typeof SpesaResponseSchema>;

export const SpesaDettaglioSchema = SpesaResponseSchema.extend({
  quote: z.array(QuotaSpesaSchema),
});
export type SpesaDettaglioDto = z.infer<typeof SpesaDettaglioSchema>;

export const PareggioContiResponseSchema = z.object({
  quotePareggiate: z.number().int(),
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
