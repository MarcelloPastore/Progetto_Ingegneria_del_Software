import "dotenv/config";
import { PrismaClient } from "@prisma/client";

declare global {
  var prisma: PrismaClient | undefined;
}

export const prisma = globalThis.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalThis.prisma = prisma;

export async function connectDB() {
  try {
    await prisma.$connect();
  } catch (error) {
    console.error("Errore connessione DB:", error);
    process.exit(1);
  }
}
