import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  registerWithValidation: vi.fn(),
  loginWithValidation: vi.fn(),
  requestPasswordResetWithValidation: vi.fn(),
  verifyPasswordResetCodeWithValidation: vi.fn(),
  resetPasswordWithValidation: vi.fn(),
  verificaEmail: vi.fn(),
}));

vi.mock("../../src/service/AuthService", () => ({
  AuthService: class {
    registerWithValidation(...args: unknown[]) {
      return mocks.registerWithValidation(...args);
    }
    loginWithValidation(...args: unknown[]) {
      return mocks.loginWithValidation(...args);
    }
    requestPasswordResetWithValidation(...args: unknown[]) {
      return mocks.requestPasswordResetWithValidation(...args);
    }
    verifyPasswordResetCodeWithValidation(...args: unknown[]) {
      return mocks.verifyPasswordResetCodeWithValidation(...args);
    }
    resetPasswordWithValidation(...args: unknown[]) {
      return mocks.resetPasswordWithValidation(...args);
    }
    verificaEmail(...args: unknown[]) {
      return mocks.verificaEmail(...args);
    }
  },
}));

import { AuthController } from "../../src/controller/AuthController";

function makeReply() {
  const reply = {
    code: vi.fn(),
    send: vi.fn(),
  };
  reply.code.mockReturnValue(reply);
  reply.send.mockReturnValue(reply);
  return reply as any;
}

function makeRequest(overrides: Record<string, unknown> = {}) {
  return {
    body: {},
    query: {},
    server: {
      jwt: {
        sign: vi.fn(() => "access-token"),
      },
    },
    ...overrides,
  } as any;
}

describe("AuthController", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("registers users and returns the public registration payload", async () => {
    mocks.registerWithValidation.mockResolvedValue({
      id: "u1",
      message: "Registrazione completata",
    });
    const controller = new AuthController();
    const reply = makeReply();
    const body = {
      email: "mario@example.com",
      username: "mario",
      password: "PasswordTest123!",
      nome: "Mario",
      cognome: "Rossi",
    };

    await controller.register(makeRequest({ body }), reply);

    expect(mocks.registerWithValidation).toHaveBeenCalledWith(body);
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith({
      message: "Registrazione completata",
      userId: "u1",
    });
  });

  it("logs users in and signs an access token", async () => {
    mocks.loginWithValidation.mockResolvedValue({
      user: {
        id: "u1",
        email: "mario@example.com",
        username: "mario",
        nome: "Mario",
        cognome: "Rossi",
      },
    });
    const controller = new AuthController();
    const request = makeRequest({
      body: { email: "mario@example.com", password: "PasswordTest123!" },
    });
    const reply = makeReply();

    await controller.login(request, reply);

    expect(request.server.jwt.sign).toHaveBeenCalledWith({
      idUtente: "u1",
      type: "access",
    });
    expect(reply.send).toHaveBeenCalledWith({
      token: "access-token",
      user: {
        idUtente: "u1",
        username: "mario",
        nome: "Mario",
      },
    });
  });

  it("delegates password recovery and email verification flows", async () => {
    mocks.requestPasswordResetWithValidation.mockResolvedValue({ ok: true });
    mocks.verifyPasswordResetCodeWithValidation.mockResolvedValue({
      valid: true,
    });
    mocks.resetPasswordWithValidation.mockResolvedValue({ changed: true });
    mocks.verificaEmail.mockResolvedValue({ verified: true });
    const controller = new AuthController();

    await controller.recuperaPassword(
      makeRequest({ body: { email: "mario@example.com" } }),
      makeReply(),
    );
    await controller.verificaCodiceRecupero(
      makeRequest({ body: { email: "mario@example.com", codice: "123456" } }),
      makeReply(),
    );
    await controller.resetPassword(
      makeRequest({
        body: {
          email: "mario@example.com",
          codice: "123456",
          nuovaPassword: "NewPassword123!",
        },
      }),
      makeReply(),
    );
    await controller.verificaEmail(
      makeRequest({
        body: undefined,
        query: { email: "mario@example.com", token: "token-123" },
      }),
      makeReply(),
    );

    expect(mocks.requestPasswordResetWithValidation).toHaveBeenCalledWith({
      email: "mario@example.com",
    });
    expect(mocks.verifyPasswordResetCodeWithValidation).toHaveBeenCalledWith({
      email: "mario@example.com",
      codice: "123456",
    });
    expect(mocks.resetPasswordWithValidation).toHaveBeenCalledWith({
      email: "mario@example.com",
      codice: "123456",
      nuovaPassword: "NewPassword123!",
    });
    expect(mocks.verificaEmail).toHaveBeenCalledWith({
      email: "mario@example.com",
      token: "token-123",
    });
  });
});
