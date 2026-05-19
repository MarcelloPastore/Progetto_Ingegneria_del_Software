import { prisma } from "../config/db";
import bcrypt from "bcrypt";
import { z } from "zod";
import { RegisterData, PublicUser } from "../dto/auth.dto";
import {
  DuplicateUserError,
  InvalidCredentialsError,
} from "../errors/appErrors";

const RegisterSchema = z.object({
  email: z.email(),
  username: z.string().min(3).max(50),
  password: z.string().min(10).max(128),
  nome: z.string().min(1).max(100),
  cognome: z.string().min(1).max(100),
});

const LoginSchema = z.object({
  email: z.email(),
  password: z.string(),
});

export class AuthService {
  async registerWithValidation(
    data: unknown,
  ): Promise<{ id: string; message: string }> {
    const validation = RegisterSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await this.register(validation.data);

    return { id: user.id, message: "Registrazione completata" };
  }

  async loginWithValidation(
    data: unknown,
  ): Promise<{ user: PublicUser; shouldSign: boolean }> {
    const validation = LoginSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await this.validateUser(
      validation.data.email,
      validation.data.password,
    );

    if (!user) {
      throw new InvalidCredentialsError();
    }

    return {
      user,
      shouldSign: true,
    };
  }

  async register(data: RegisterData) {
    const existingByEmail = await prisma.utente.findUnique({
      where: { email: data.email },
    });

    if (existingByEmail) {
      throw new DuplicateUserError();
    }

    const existingByUsername = await prisma.utente.findUnique({
      where: { username: data.username },
    });

    if (existingByUsername) {
      throw new DuplicateUserError();
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    return prisma.utente.create({
      data: {
        email: data.email,
        username: data.username,
        password: hashedPassword,
        nome: data.nome,
        cognome: data.cognome,
      },
    });
  }

  async validateUser(
    email: string,
    password: string,
  ): Promise<PublicUser | null> {
    const user = await prisma.utente.findUnique({ where: { email } });

    if (!user) return null;

    const match = await bcrypt.compare(password, user.password);
    if (!match) return null;

    return {
      id: user.id,
      email: user.email,
      username: user.username,
      nome: user.nome,
      cognome: user.cognome,
    };
  }
}
