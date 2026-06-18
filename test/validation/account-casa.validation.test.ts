import { describe, it, expect } from "vitest";
import { Ruolo } from "@prisma/client";
import {
  ModificaEmailDto,
  ModificaPasswordDto,
  ModificaUsernameDto,
  UserProfileDto,
} from "../../src/dto/AccountDto";
import {
  AggiungiInquilinoSchema,
  CasaResponseSchema,
  CasaSummarySchema,
  CreaCasaSchema,
  InquilinoSchema,
  InviteLinkSchema,
  ModificaCasaSchema,
  ModificaRuoloSchema,
} from "../../src/dto/CasaDto";

describe("AccountDto validation", () => {
  it("validates profile and account update DTOs", () => {
    expect(ModificaUsernameDto.safeParse({ username: "mario" }).success).toBe(
      true,
    );
    expect(ModificaEmailDto.safeParse({ email: "mario@example.com" }).success)
      .toBe(true);
    expect(
      ModificaPasswordDto.safeParse({
        oldPassword: "old-password",
        newPassword: "new-password",
      }).success,
    ).toBe(true);
    expect(
      UserProfileDto.safeParse({
        username: "mario",
        nome: "Mario",
        cognome: "Rossi",
        email: "mario@example.com",
        dataCreazione: "2026-06-01T00:00:00.000Z",
      }).success,
    ).toBe(true);
  });

  it("rejects invalid account update DTOs", () => {
    expect(ModificaUsernameDto.safeParse({ username: "ab" }).success).toBe(
      false,
    );
    expect(ModificaEmailDto.safeParse({ email: "bad" }).success).toBe(false);
    expect(
      ModificaPasswordDto.safeParse({
        oldPassword: "same-password",
        newPassword: "same-password",
      }).success,
    ).toBe(false);
  });
});

describe("CasaDto validation", () => {
  const inquilino = {
    id: "m1",
    utente: { id: "u1", username: "mario" },
    ruolo: Ruolo.HomeAdmin,
    dataIngresso: "2026-06-01T00:00:00.000Z",
  };

  const summary = {
    id: "c1",
    nome: "Casa Milano",
    indirizzo: "Via Roma",
    citta: "Milano",
    tipoCasa: "Appartamento",
    inviteLink: "invite",
    dataCreazione: "2026-06-01T00:00:00.000Z",
    creator: { id: "u1", username: "mario" },
    ruoloUtente: Ruolo.HomeAdmin,
    membriTotali: 1,
  };

  it("validates house create/update and membership DTOs", () => {
    expect(CreaCasaSchema.safeParse({ nome: "Casa Milano" }).success).toBe(
      true,
    );
    expect(ModificaCasaSchema.safeParse({ citta: "Roma" }).success).toBe(true);
    expect(
      AggiungiInquilinoSchema.safeParse({ inviteLink: "invite" }).success,
    ).toBe(true);
    expect(
      ModificaRuoloSchema.safeParse({ ruolo: Ruolo.Inquilino }).success,
    ).toBe(true);
    expect(InquilinoSchema.safeParse(inquilino).success).toBe(true);
    expect(CasaSummarySchema.safeParse(summary).success).toBe(true);
    expect(
      CasaResponseSchema.safeParse({ ...summary, membri: [inquilino] }).success,
    ).toBe(true);
    expect(InviteLinkSchema.safeParse({ inviteLink: "invite" }).success).toBe(
      true,
    );
  });

  it("rejects invalid house DTOs", () => {
    expect(CreaCasaSchema.safeParse({ nome: "" }).success).toBe(false);
    expect(AggiungiInquilinoSchema.safeParse({ inviteLink: "" }).success).toBe(
      false,
    );
    expect(ModificaRuoloSchema.safeParse({ ruolo: "Owner" }).success).toBe(
      false,
    );
  });
});
