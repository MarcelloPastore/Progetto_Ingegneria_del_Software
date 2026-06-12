import { z } from "zod";

export const AssegnatarioInfoSchema = z.object({
  id: z.string(),
  username: z.string(),
  nome: z.string().optional(),
  cognome: z.string().optional(),
  email: z.string().optional(),
});
export type AssegnatarioInfoDto = z.infer<typeof AssegnatarioInfoSchema>;
