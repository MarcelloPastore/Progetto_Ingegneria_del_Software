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
