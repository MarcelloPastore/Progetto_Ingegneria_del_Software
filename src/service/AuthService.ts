import { prisma } from "../config/db";
import argon2 from "argon2";
import { randomBytes, randomInt } from "node:crypto";
import {
  RegisterSchema,
  LoginSchema,
  VerifyEmailSchema,
  RequestPasswordResetSchema,
  VerifyPasswordResetCodeSchema,
  ResetPasswordSchema,
} from "../schemas/authSchemas";
import { RegisterData, PublicUser } from "../dto/auth.dto";
import {
  DuplicateUserError,
  InvalidCredentialsError,
  UserNotFoundError,
  InvalidOrExpiredResetCodeError,
  EmailDeliveryError,
  PasswordResetEmailDeliveryError,
  InvalidEmailVerificationTokenError,
  DatabaseCleanupError,
} from "../errors/appErrors";
import type { VerificationMailInput } from "../utils/mail";
import {
  sendVerificationEmail,
  sendPasswordResetEmail,
  type PasswordResetMailInput,
} from "../utils/mail";

type AuthServiceMailers = {
  sendVerificationMail?: (input: VerificationMailInput) => Promise<void>;
  sendPasswordResetMail?: (input: PasswordResetMailInput) => Promise<void>;
};

export class AuthService {
  private readonly sendVerificationMail: (
    input: VerificationMailInput,
  ) => Promise<void>;

  private readonly sendPasswordResetMail: (
    input: PasswordResetMailInput,
  ) => Promise<void>;

  constructor(mailers: AuthServiceMailers = {}) {
    this.sendVerificationMail =
      mailers.sendVerificationMail ?? sendVerificationEmail;
    this.sendPasswordResetMail =
      mailers.sendPasswordResetMail ?? sendPasswordResetEmail;
  }

  private readonly resetCodes = new Map<
    string,
    { codice: string; expiresAtMs: number }
  >();

  private emailKey(email: string): string {
    return email.trim().toLowerCase();
  }

  private generateResetCode(): string {
    return randomInt(0, 1_000_000).toString().padStart(6, "0");
  }

  private generateVerificationToken(): string {
    return randomBytes(32).toString("hex");
  }

  private async cleanupFailedRegistration(userId: string): Promise<void> {
    try {
      await prisma.utente.delete({ where: { id: userId } });
    } catch {
      throw new DatabaseCleanupError();
    }
  }

  private ensureValidResetCode(params: {
    codiceAtteso?: string;
    scadenzaMs?: number;
    codiceRicevuto: string;
  }): void {
    const { codiceAtteso, scadenzaMs, codiceRicevuto } = params;
    const isExpired = !scadenzaMs || scadenzaMs < Date.now();

    if (!codiceAtteso || codiceAtteso !== codiceRicevuto || isExpired) {
      throw new InvalidOrExpiredResetCodeError();
    }
  }

  async registerWithValidation(
    data: unknown,
  ): Promise<{ id: string; message: string }> {
    const validation = RegisterSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const verificationToken = this.generateVerificationToken();
    const user = await this.register(validation.data, verificationToken);

    try {
      await this.sendVerificationMail({
        to: user.email,
        username: user.username,
        verificationToken,
      });
    } catch {
      await this.cleanupFailedRegistration(user.id);
      throw new EmailDeliveryError();
    }

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

  async register(data: RegisterData, tokenVerifica: string) {
    const existingByEmail = await prisma.utente.findUnique({
      where: { email: data.email },
    });

    if (existingByEmail) {
      throw new DuplicateUserError("L'email è già in uso.");
    }

    const existingByUsername = await prisma.utente.findFirst({
      where: { username: data.username },
    });

    if (existingByUsername) {
      throw new DuplicateUserError("L'email è già in uso.");
    }

    const hashedPassword = await argon2.hash(data.password, {
      type: argon2.argon2id,
    });

    return prisma.utente.create({
      data: {
        email: data.email,
        username: data.username,
        passwordHash: hashedPassword,
        nome: data.nome,
        cognome: data.cognome,
        tokenVerifica,
      },
    });
  }

  async validateUser(
    email: string,
    password: string,
  ): Promise<PublicUser | null> {
    const user = await prisma.utente.findUnique({ where: { email } });

    if (!user) return null;

    const match = await argon2.verify(user.passwordHash, password);
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
    const validation = VerifyEmailSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await prisma.utente.findUnique({
      where: { email: validation.data.email },
    });

    if (!user) {
      throw new InvalidCredentialsError();
    }

    if (user.emailVerificata) {
      return {
        ok: true,
        date: user.dataVerificaMail?.toISOString() ?? new Date().toISOString(),
      };
    }

    if (!user.tokenVerifica || user.tokenVerifica !== validation.data.token) {
      throw new InvalidEmailVerificationTokenError();
    }

    const now = new Date();

    await prisma.utente.update({
      where: { id: user.id },
      data: {
        emailVerificata: true,
        dataVerificaMail: now,
        tokenVerifica: null,
      },
    });

    return {
      ok: true,
      date: now.toISOString(),
      //user: {
      //  id: user.id,
      //  nome: user.nome,
      //  username: user.username,
      //},
    };
  }

  async requestPasswordResetWithValidation(
    data: unknown,
  ): Promise<{ ok: boolean; date: string; expiresAt: string }> {
    const validation = RequestPasswordResetSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await prisma.utente.findUnique({
      where: { email: validation.data.email },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    const codice = this.generateResetCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    this.resetCodes.set(this.emailKey(user.email), {
      codice,
      expiresAtMs: expiresAt.getTime(),
    });

    try {
      await this.sendPasswordResetMail({
        to: user.email,
        username: user.username,
        resetCode: codice,
        expiresAt: expiresAt.toISOString(),
      });
    } catch {
      this.resetCodes.delete(this.emailKey(user.email));
      throw new PasswordResetEmailDeliveryError();
    }

    return {
      ok: true,
      date: new Date().toISOString(),
      expiresAt: expiresAt.toISOString(),
    };
  }

  async verifyPasswordResetCodeWithValidation(
    data: unknown,
  ): Promise<{ ok: boolean; date: string }> {
    const validation = VerifyPasswordResetCodeSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await prisma.utente.findUnique({
      where: { email: validation.data.email },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    const resetEntry = this.resetCodes.get(
      this.emailKey(validation.data.email),
    );

    this.ensureValidResetCode({
      codiceAtteso: resetEntry?.codice,
      scadenzaMs: resetEntry?.expiresAtMs,
      codiceRicevuto: validation.data.codice,
    });

    return {
      ok: true,
      date: new Date().toISOString(),
    };
  }

  async resetPasswordWithValidation(
    data: unknown,
  ): Promise<{ ok: boolean; date: string }> {
    const validation = ResetPasswordSchema.safeParse(data);
    if (!validation.success) {
      throw validation.error;
    }

    const user = await prisma.utente.findUnique({
      where: { email: validation.data.email },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    const email = this.emailKey(validation.data.email);
    const resetEntry = this.resetCodes.get(email);

    this.ensureValidResetCode({
      codiceAtteso: resetEntry?.codice,
      scadenzaMs: resetEntry?.expiresAtMs,
      codiceRicevuto: validation.data.codice,
    });

    const hashedPassword = await argon2.hash(validation.data.nuovaPassword, {
      type: argon2.argon2id,
    });

    await prisma.utente.update({
      where: { id: user.id },
      data: {
        passwordHash: hashedPassword,
      },
    });

    this.resetCodes.delete(email);

    return {
      ok: true,
      date: new Date().toISOString(),
    };
  }
}
