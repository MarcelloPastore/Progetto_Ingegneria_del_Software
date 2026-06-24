import { Ruolo } from "@prisma/client";
import { z } from "zod";
import { AssegnatarioInfoSchema } from "./AssegnatarioDto";

const ruoloSchema = z.enum([Ruolo.SysAdmin, Ruolo.HomeAdmin, Ruolo.Inquilino]);

export const CreaCasaSchema = z.object({
  nome: z.string().min(1, "Campo obbligatorio"),
  indirizzo: z.string().optional(),
  citta: z.string().optional(),
  tipoCasa: z.string().optional(),
});
export type CreaCasaDto = z.infer<typeof CreaCasaSchema>;

export const ModificaCasaSchema = CreaCasaSchema.partial();
export type ModificaCasaDto = z.infer<typeof ModificaCasaSchema>;

export const AggiungiInquilinoSchema = z.object({
  inviteLink: z.string().min(1, "Invite link obbligatorio"),
});
export type AggiungiInquilinoDto = z.infer<typeof AggiungiInquilinoSchema>;

export const JoinCasaSchema = z.object({
  inviteCode: z
    .string()
    .regex(/^CX-[A-Z0-9]{8}$/, "Formato codice non valido (es. CX-MDLE4H58)"),
});
export type JoinCasaDto = z.infer<typeof JoinCasaSchema>;

export const ModificaRuoloSchema = z.object({
  ruolo: ruoloSchema,
});
export type ModificaRuoloDto = z.infer<typeof ModificaRuoloSchema>;

export const InquilinoSchema = z.object({
  id: z.string(),
  utente: AssegnatarioInfoSchema,
  ruolo: ruoloSchema,
  dataIngresso: z.coerce.date(),
});
export type InquilinoDto = z.infer<typeof InquilinoSchema>;

export const CasaSummarySchema = z.object({
  id: z.string(),
  nome: z.string(),
  indirizzo: z.string().nullable(),
  citta: z.string().nullable(),
  tipoCasa: z.string().nullable(),
  inviteLink: z.string().nullable(),
  dataCreazione: z.coerce.date(),
  creator: AssegnatarioInfoSchema,
  ruoloUtente: ruoloSchema,
  membriTotali: z.number().int().nonnegative(),
});
export type CasaSummaryDto = z.infer<typeof CasaSummarySchema>;

export const CasaResponseSchema = CasaSummarySchema.extend({
  membri: z.array(InquilinoSchema),
});
export type CasaResponseDto = z.infer<typeof CasaResponseSchema>;

export const InviteLinkSchema = z.object({
  inviteLink: z.string(),
});
export type InviteLinkDto = z.infer<typeof InviteLinkSchema>;

export const HubCasaSchema = z.object({
  casa: CasaResponseSchema,
  ruolo: ruoloSchema,
  speseCount: z.number().int().nonnegative(),
  scadenzeCount: z.number().int().nonnegative(),
  problemiCount: z.number().int().nonnegative(),
  turniCount: z.number().int().nonnegative(),
});
export type HubCasaDto = z.infer<typeof HubCasaSchema>;
