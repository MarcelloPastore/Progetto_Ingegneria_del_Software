import { describe, it, expect, vi } from "vitest";
import { z } from "zod";
import { sendErrorReply } from "../../src/utils/errorReply";

describe("sendErrorReply", () => {
  it("formats mapped errors into Fastify replies", () => {
    const reply = {
      code: vi.fn(),
      send: vi.fn(),
    };
    reply.code.mockReturnValue(reply);

    const result = z.object({ email: z.string().email() }).safeParse({
      email: "bad",
    });
    const error = result.success ? new Error("unexpected") : result.error;

    sendErrorReply(reply as any, error);

    expect(reply.code).toHaveBeenCalledWith(400);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        error: "Dati non validi",
        message: "Dati non validi",
        code: "BAD_REQUEST",
        details: { email: expect.any(Array) },
      }),
    );
  });
});
