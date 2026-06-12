import { PrismaClient } from "@prisma/client";

declare global {
  var prisma: PrismaClient | undefined;
}

export const prisma: PrismaClient = globalThis.prisma ?? new PrismaClient();
globalThis.prisma = prisma;

export async function connectDB() {
  try {
    await prisma.$connect();
  } catch (error) {
    console.error("Errore connessione DB:", error);
    process.exit(1);
  }
}
