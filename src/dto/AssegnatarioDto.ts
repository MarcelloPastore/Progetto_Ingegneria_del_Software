import { z } from "zod";

export const AssegnatarioInfoSchema = z.object({
  id: z.string(),
  username: z.string(),
});
export type AssegnatarioInfoDto = z.infer<typeof AssegnatarioInfoSchema>;
