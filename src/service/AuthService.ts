import { prisma } from "../config/db";
import argon2 from "argon2";
import {
  RegisterSchema,
  LoginSchema,
  EmailSchema,
} from "../schemas/authSchemas";
import { RegisterData, PublicUser } from "../dto/auth.dto";
import {
  DuplicateUserError,
  InvalidCredentialsError,
} from "../errors/appErrors";

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

    const hashedPassword = await argon2.hash(data.password, {
      type: argon2.argon2id,
    });

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

    const match = await argon2.verify(user.password, password);
    if (!match) return null;

    return {
      id: user.id,
      email: user.email,
      username: user.username,
      nome: user.nome,
      cognome: user.cognome,
    };
  }

  async verificaEmail(data: unknown): Promise<{ ok: boolean; date: string }> {
    const validation = EmailSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await prisma.utente.findUnique({
      where: { email: validation.data.email },
    });

    if (!user) {
      throw new InvalidCredentialsError();
    }

    const now = new Date();

    await prisma.utente.update({
      where: { id: user.id },
      data: {
        emailVerificata: true,
        dataVerificaMail: now,
      },
    });

    return {
      ok: true,
      date: now.toISOString(),
    };
  }
}
