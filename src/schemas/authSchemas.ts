import { z } from "zod";

export const RegisterSchema = z.object({
  email: z.email(),
  username: z.string().min(3).max(50),
  password: z.string().min(10).max(128),
  nome: z.string().min(1).max(100),
  cognome: z.string().min(1).max(100),
});

export const LoginSchema = z.object({
  email: z.email(),
  password: z.string(),
});

export const EmailSchema = z.object({
  email: z.email(),
});

export const VerifyEmailSchema = z.object({
  email: z.email(),
  token: z.string().min(1),
});

export const RequestPasswordResetSchema = z.object({
  email: z.email(),
});

export const VerifyPasswordResetCodeSchema = z.object({
  email: z.email(),
  codice: z.string().regex(/^\d{6}$/, "Il codice deve contenere 6 cifre"),
});

export const ResetPasswordSchema = z.object({
  email: z.email(),
  codice: z.string().regex(/^\d{6}$/, "Il codice deve contenere 6 cifre"),
  nuovaPassword: z.string().min(10).max(128),
});
