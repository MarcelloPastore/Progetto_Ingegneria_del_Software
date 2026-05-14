import { prisma } from "../config/db";
import bcrypt from "bcrypt";
import { Ruolo } from "@prisma/client";

interface RegisterData {
  email: string;
  password: string;
  nome: string;
  cognome: string;
  ruolo?: Ruolo;
}

export interface PublicUser {
  id: string;
  email: string;
  nome: string;
  cognome: string;
  ruolo: Ruolo;
}

export class AuthService {
  async register(data: RegisterData) {
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (existingUser) {
      throw new Error("L'utente esiste già");
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    return prisma.user.create({
      data: {
        email: data.email,
        password: hashedPassword,
        nome: data.nome,
        cognome: data.cognome,
        ruolo: data.ruolo ?? Ruolo.Inquilino,
      },
    });
  }

  async validateUser(
    email: string,
    password: string,
  ): Promise<PublicUser | null> {
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) return null;

    const match = await bcrypt.compare(password, user.password);
    if (!match) return null;

    return {
      id: user.id,
      email: user.email,
      nome: user.nome,
      cognome: user.cognome,
      ruolo: user.ruolo,
    };
  }
}
