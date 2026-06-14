import { Ruolo } from "@prisma/client";
import { prisma } from "../config/db";
import { randomBytes } from "node:crypto";
import argon2 from "argon2";
import {
  ModificaUsernameDto,
  ModificaEmailDto,
  ModificaPasswordDto,
  UserProfileDto,
} from "../dto/AccountDto";
import {
  UserNotFoundError,
  EmailDeliveryError,
  DuplicateUserError,
  InvalidCurrentPasswordError,
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

  async modificaPassword(
    idUtente: string,
    dto: ModificaPasswordDto,
  ): Promise<{ message: string }> {
    const user = await prisma.utente.findUnique({
      where: { id: idUtente },
      select: { id: true, passwordHash: true },
    });

    if (!user) {
      throw new UserNotFoundError();
    }

    const isValid = await argon2.verify(user.passwordHash, dto.oldPassword);
    if (!isValid) {
      throw new InvalidCurrentPasswordError();
    }

    const newHash = await argon2.hash(dto.newPassword);
    await prisma.utente.update({
      where: { id: idUtente },
      data: { passwordHash: newHash },
    });

    return { message: "Password modificata con successo." };
  }

  async eliminaAccount(idUtente: string): Promise<{ message: string }> {
    await prisma.$transaction(async (tx) => {
      const user = await tx.utente.findUnique({
        where: { id: idUtente },
        select: { id: true },
      });

      if (!user) {
        throw new UserNotFoundError();
      }

      // Carica tutte le membership dell'utente
      const memberships = await tx.membroCasa.findMany({
        where: { idUtente },
        select: { id: true, idCasa: true, ruolo: true },
      });

      for (const membership of memberships) {
        const { id: idMembership, idCasa, ruolo } = membership;

        const allMembers = await tx.membroCasa.findMany({
          where: { idCasa },
          select: { id: true, idUtente: true, ruolo: true },
        });

        if (allMembers.length === 1) {
          // Ultimo membro: elimina la casa e tutte le sue entità
          await tx.quotaSpesa.deleteMany({ where: { idCasa } });
          await tx.spesa.deleteMany({ where: { idCasa } });
          await tx.turno.deleteMany({ where: { idCasa } });
          await tx.problema.deleteMany({ where: { idCasa } });
          await tx.documento.deleteMany({ where: { idCasa } });
          await tx.scadenza.deleteMany({ where: { idCasa } });
          await tx.membroCasa.deleteMany({ where: { idCasa } });
          await tx.casa.delete({ where: { id: idCasa } });
        } else {
          // Ci sono altri membri
          if (ruolo === Ruolo.HomeAdmin) {
            const altriAdmin = allMembers.filter(
              (m) => m.idUtente !== idUtente && m.ruolo === Ruolo.HomeAdmin,
            );

            if (altriAdmin.length === 0) {
              // Ultimo admin: promuovi un membro random
              const altriMembri = allMembers.filter(
                (m) => m.idUtente !== idUtente,
              );
              const nuovoAdmin =
                altriMembri[Math.floor(Math.random() * altriMembri.length)];
              await tx.membroCasa.update({
                where: { id: nuovoAdmin.id },
                data: { ruolo: Ruolo.HomeAdmin },
              });
            }
          }

          await tx.membroCasa.delete({ where: { id: idMembership } });
        }
      }

      // Anonimizza i dati dell'utente
      await tx.utente.update({
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
    });

    return {
      message: "Account eliminato e dati anonimizzati con successo.",
    };
  }
}
