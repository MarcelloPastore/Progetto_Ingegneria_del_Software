import { z } from "zod";

export const CreaCasaSchema = z.object({
  nome: z.string().trim().min(1, "Nome casa richiesto"),
  indirizzo: z.string().trim(),
  citta: z.string().trim(),
  tipoCasa: z.string().trim().min(1, "Tipo casa richiesto"),
});

export type CreaCasaDto = z.infer<typeof CreaCasaSchema>;
