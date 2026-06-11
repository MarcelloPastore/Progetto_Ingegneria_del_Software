import { prisma } from "../config/db";
import { randomBytes } from "node:crypto";
import {
  ModificaUsernameDto,
  ModificaEmailDto,
  UserProfileDto,
} from "../dto/AccountDto";
import {
  UserNotFoundError,
  EmailDeliveryError,
  DuplicateUserError,
} from "../errors/appErrors";
import { ConflictError } from "../errors/httpErrors";
import type { VerificationMailInput } from "../utils/mail";
import { sendVerificationEmail } from "../utils/mail";

export class AccountService {
  private readonly sendVerificationMail: (
    input: VerificationMailInput,
  ) => Promise<void>;

  constructor(mailers?: {
    sendVerificationMail?: (input: VerificationMailInput) => Promise<void>;
  }) {
    this.sendVerificationMail =
      mailers?.sendVerificationMail ?? sendVerificationEmail;
  }

  private generateVerificationToken(): string {
    return randomBytes(32).toString("hex");
  }

  async getProfilo(idUtente: string): Promise<UserProfileDto> {
    const user = await prisma.utente.findUnique({
      where: { id: idUtente },
      select: {
        username: true,
        nome: true,
        cognome: true,
        email: true,
        dataCreazione: true,
      },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    return {
      username: user.username,
      nome: user.nome,
      cognome: user.cognome,
      email: user.email,
      dataCreazione: user.dataCreazione,
    };
  }

  async modificaUsername(
    idUtente: string,
    dto: ModificaUsernameDto,
  ): Promise<UserProfileDto> {
    const existingUser = await prisma.utente.findFirst({
      where: {
        username: dto.username,
        id: { not: idUtente },
      },
    });

    if (existingUser) {
      throw new ConflictError("Lo username è già in uso.");
    }

    return prisma.utente.update({
      where: { id: idUtente },
      data: {
        username: dto.username,
      },
      select: {
        username: true,
        nome: true,
        cognome: true,
        email: true,
        dataCreazione: true,
      },
    });
  }

  async modificaEmail(
    idUtente: string,
    dto: ModificaEmailDto,
  ): Promise<{ message: string; newEmail: string }> {
    const user = await prisma.utente.findUnique({
      where: { id: idUtente },
      select: {
        id: true,
        username: true,
        email: true,
        emailVerificata: true,
        tokenVerifica: true,
        dataVerificaMail: true,
      },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    const oldEmail = user.email;
    const oldEmailVerificata = user.emailVerificata;
    const oldTokenVerifica = user.tokenVerifica;
    const oldDataVerificaMail = user.dataVerificaMail;

    const existingUser = await prisma.utente.findUnique({
      where: { email: dto.email },
    });

    if (existingUser && existingUser.id !== idUtente) {
      throw new DuplicateUserError();
    }

    const verificationToken = this.generateVerificationToken();

    await prisma.utente.update({
      where: { id: idUtente },
      data: {
        email: dto.email,
        emailVerificata: false,
        tokenVerifica: verificationToken,
        dataVerificaMail: null,
      },
    });

    try {
      await this.sendVerificationMail({
        to: dto.email,
        username: user.username,
        verificationToken,
      });
    } catch {
      await prisma.utente.update({
        where: { id: idUtente },
        data: {
          email: oldEmail,
          emailVerificata: oldEmailVerificata,
          tokenVerifica: oldTokenVerifica,
          dataVerificaMail: oldDataVerificaMail,
        },
      });

      throw new EmailDeliveryError();
    }

    return {
      message:
        "Email modificata con successo. Verifica il tuo indirizzo per completare il cambio.",
      newEmail: dto.email,
    };
  }

  async eliminaAccount(idUtente: string): Promise<{ message: string }> {
    const user = await prisma.utente.findUnique({
      where: { id: idUtente },
      select: { id: true },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    await prisma.utente.update({
      where: { id: idUtente },
      data: {
        username: `Utente_${idUtente.substring(0, 8)}`,
        email: `deleted_${idUtente}@deleted.local`,
        nome: "Anonimo",
        cognome: "Anonimo",
        passwordHash: "DELETED",
        emailVerificata: false,
        tokenVerifica: null,
        fcmToken: null,
      },
    });

    return {
      message: "Account eliminato e dati anonimizzati con successo.",
    };
  }
}
