/**
 * VALIDATION TESTS — Auth schemas (Zod)
 *
 * Scopo:
 * - verificare il contratto degli endpoint di autenticazione: register/login/reset
 * - garantire che i vincoli (email valida, password min length, codice 6 cifre) restino stabili
 */
import { describe, it, expect } from "vitest";
import {
  RegisterSchema,
  LoginSchema,
  EmailSchema,
  RequestPasswordResetSchema,
  VerifyPasswordResetCodeSchema,
  ResetPasswordSchema,
} from "../../src/schemas/authSchemas";

describe("Auth schemas - validation", () => {
  it("RegisterSchema accepts valid payload", () => {
    const result = RegisterSchema.safeParse({
      email: "mario.rossi@example.com",
      username: "mario",
      password: "super-secure-123",
      nome: "Mario",
      cognome: "Rossi",
    });
    expect(result.success).toBe(true);
  });

  it("RegisterSchema rejects short password", () => {
    const result = RegisterSchema.safeParse({
      email: "mario.rossi@example.com",
      username: "mario",
      password: "short",
      nome: "Mario",
      cognome: "Rossi",
    });
    expect(result.success).toBe(false);
  });

  it("LoginSchema rejects invalid email", () => {
    const result = LoginSchema.safeParse({
      email: "not-an-email",
      password: "whatever",
    });
    expect(result.success).toBe(false);
  });

  it("VerifyPasswordResetCodeSchema requires 6 digits", () => {
    const result = VerifyPasswordResetCodeSchema.safeParse({
      email: "mario@example.com",
      codice: "12345",
    });
    expect(result.success).toBe(false);
  });

  it("ResetPasswordSchema accepts valid payload", () => {
    const result = ResetPasswordSchema.safeParse({
      email: "mario@example.com",
      codice: "123456",
      nuovaPassword: "new-password-123",
    });
    expect(result.success).toBe(true);
  });

  it("EmailSchema / RequestPasswordResetSchema accept valid email", () => {
    expect(EmailSchema.safeParse({ email: "test@example.com" }).success).toBe(
      true,
    );
    expect(
      RequestPasswordResetSchema.safeParse({ email: "test@example.com" })
        .success,
    ).toBe(true);
  });
});

