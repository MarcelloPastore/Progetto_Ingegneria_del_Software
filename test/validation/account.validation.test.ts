/**
 * VALIDATION TESTS — AccountDto (Zod schemas)
 *
 * Scopo:
 * - verificare i contratti degli endpoint account: username, email, password
 * - garantire che i vincoli (lunghezza minima, formato email, stessa password) restino stabili
 */
import { describe, it, expect } from "vitest";
import {
  ModificaUsernameDto,
  ModificaEmailDto,
  ModificaPasswordDto,
} from "../../src/dto/AccountDto";

describe("AccountDto - validation", () => {
  describe("ModificaUsernameDto", () => {
    it("accepts username with 3 characters (minimum)", () => {
      const result = ModificaUsernameDto.safeParse({ username: "abc" });
      expect(result.success).toBe(true);
    });

    it("accepts long username", () => {
      const result = ModificaUsernameDto.safeParse({ username: "mario_rossi_2026" });
      expect(result.success).toBe(true);
    });

    it("rejects username with 2 characters (below minimum)", () => {
      const result = ModificaUsernameDto.safeParse({ username: "ab" });
      expect(result.success).toBe(false);
    });

    it("rejects empty username", () => {
      const result = ModificaUsernameDto.safeParse({ username: "" });
      expect(result.success).toBe(false);
    });

    it("rejects missing username", () => {
      const result = ModificaUsernameDto.safeParse({});
      expect(result.success).toBe(false);
    });
  });

  describe("ModificaEmailDto", () => {
    it("accepts valid email address", () => {
      const result = ModificaEmailDto.safeParse({ email: "mario.rossi@example.com" });
      expect(result.success).toBe(true);
    });

    it("rejects malformed email (no @)", () => {
      const result = ModificaEmailDto.safeParse({ email: "not-an-email" });
      expect(result.success).toBe(false);
    });

    it("rejects empty string", () => {
      const result = ModificaEmailDto.safeParse({ email: "" });
      expect(result.success).toBe(false);
    });

    it("rejects missing email field", () => {
      const result = ModificaEmailDto.safeParse({});
      expect(result.success).toBe(false);
    });
  });

  describe("ModificaPasswordDto", () => {
    it("accepts valid old and new passwords", () => {
      const result = ModificaPasswordDto.safeParse({
        oldPassword: "old-password-123",
        newPassword: "new-password-456",
      });
      expect(result.success).toBe(true);
    });

    it("rejects oldPassword shorter than 10 characters", () => {
      const result = ModificaPasswordDto.safeParse({
        oldPassword: "short",
        newPassword: "new-password-456",
      });
      expect(result.success).toBe(false);
    });

    it("rejects newPassword shorter than 10 characters", () => {
      const result = ModificaPasswordDto.safeParse({
        oldPassword: "old-password-123",
        newPassword: "short",
      });
      expect(result.success).toBe(false);
    });

    it("rejects when old and new password are identical", () => {
      const result = ModificaPasswordDto.safeParse({
        oldPassword: "same-password-123",
        newPassword: "same-password-123",
      });
      expect(result.success).toBe(false);
    });

    it("rejects missing newPassword", () => {
      const result = ModificaPasswordDto.safeParse({ oldPassword: "old-password-123" });
      expect(result.success).toBe(false);
    });
  });
});
