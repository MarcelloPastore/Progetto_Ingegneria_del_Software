import { z } from "zod";

export const ModificaUsernameDto = z.object({
  username: z.string().min(3, "Lo username deve contenere almeno 3 caratteri."),
});
export type ModificaUsernameDto = z.infer<typeof ModificaUsernameDto>;

export const ModificaEmailDto = z.object({
  email: z.email("L'email non è valida."),
});
export type ModificaEmailDto = z.infer<typeof ModificaEmailDto>;

export const ModificaPasswordDto = z
  .object({
    oldPassword: z
      .string()
      .min(10, "La vecchia password deve contenere almeno 10 caratteri."),
    newPassword: z
      .string()
      .min(10, "La nuova password deve contenere almeno 10 caratteri."),
  })
  .refine((data) => data.oldPassword !== data.newPassword, {
    message: "La nuova password non può essere uguale a quella attuale.",
    path: ["newPassword"],
  });
export type ModificaPasswordDto = z.infer<typeof ModificaPasswordDto>;

export const UserProfileDto = z.object({
  username: z.string(),
  nome: z.string(),
  cognome: z.string(),
  email: z.email(),
  dataCreazione: z.coerce.date(),
});
export type UserProfileDto = z.infer<typeof UserProfileDto>;
