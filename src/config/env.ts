import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
    MONGODB_URI: z.string().trim().min(1, "MONGODB_URI mancante"),
    JWT_SECRET: z.string().trim().min(1, "JWT_SECRET mancante"),
    JWT_ACCESS_TTL: z.string().trim().min(1).default("14d"),
    PORT: z.coerce.number().int().positive().default(23109),
});

export const env = envSchema.parse(process.env);