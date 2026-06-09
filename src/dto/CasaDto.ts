import { z } from "zod";
import { Ruolo } from "@prisma/client";

export const CreaCasaSchema = z.object({
  nome: z.string().trim().min(1, "Nome casa richiesto"),
  indirizzo: z.string().trim(),
  citta: z.string().trim(),
  tipoCasa: z.string().trim().min(1, "Tipo casa richiesto"),
});

export type CreaCasaDto = z.infer<typeof CreaCasaSchema>;

export const ModificaCasaSchema = CreaCasaSchema.partial().refine(
  (data) => Object.keys(data).length > 0,
  "Almeno un campo da modificare richiesto",
);

export type ModificaCasaDto = z.infer<typeof ModificaCasaSchema>;

export const AggiungiInquilinoSchema = z
  .object({
    idUtente: z.string().trim().min(1).optional(),
    inviteCode: z.string().trim().min(1).optional(),
    codiceInvito: z.string().trim().min(1).optional(),
    inviteLink: z.string().trim().min(1).optional(),
  })
  .refine(
    (data) => data.inviteCode || data.codiceInvito || data.inviteLink,
    "Codice o link di invito richiesto",
  );

export type AggiungiInquilinoDto = z.infer<typeof AggiungiInquilinoSchema>;

export const ModificaRuoloInquilinoSchema = z.object({
  ruolo: z.enum([Ruolo.HomeAdmin, Ruolo.Inquilino]),
});

export type ModificaRuoloInquilinoDto = z.infer<
  typeof ModificaRuoloInquilinoSchema
>;

export type InquilinoCasaDto = {
  id: string;
  idUtente: string;
  nome: string;
  cognome: string;
  username: string;
  email: string;
  ruolo: Ruolo;
  dataIngresso: string;
  isOwner: boolean;
};
