import { z } from "zod";

const envSchema = z.object({
  MONGODB_URI: z.string().trim().min(1, "MONGODB_URI mancante"),
  JWT_SECRET: z.string().trim().min(1, "JWT_SECRET mancante"),
  JWT_ACCESS_TTL: z.string().trim().min(1).default("14d"),
  PORT: z.coerce.number().int().positive().default(23109),
  APP_PUBLIC_URL: z.string().trim().min(1).default("http://localhost:23109"),
  MAIL_HOST: z.string().trim().min(1).default("localhost"),
  MAIL_PORT: z.coerce.number().int().positive().default(1025),
  MAIL_FROM: z.string().trim().min(1).default("no-reply@coincasa.local"),
  MAIL_FROM_NAME: z.string().trim().optional().default(""),
  MAIL_FROM_EMAIL: z.string().trim().optional().default(""),
  MAIL_SECURE: z
    .preprocess((v) => {
      if (v === undefined || v === null || v === "") {
        return false;
      }

      if (typeof v === "string") {
        return v === "true" || v === "1";
      }

      return Boolean(v);
    }, z.boolean())
    .optional()
    .default(false),
  MAIL_USER: z.string().trim().optional().default(""),
  MAIL_PASSWORD: z.string().trim().optional().default(""),
});

export const env = envSchema.parse(process.env);
