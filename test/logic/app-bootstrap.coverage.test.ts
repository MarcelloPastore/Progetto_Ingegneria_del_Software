import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  fastifyHelmet: vi.fn(),
  fastifyJwt: vi.fn(),
  fastifyRateLimit: vi.fn(),
  routes: {
    accountRoutes: vi.fn(),
    authRoutes: vi.fn(),
    casaRoutes: vi.fn(),
    health: vi.fn(),
    problemiRoutes: vi.fn(),
    scadenzeRoutes: vi.fn(),
    speseRoutes: vi.fn(),
    turniRoutes: vi.fn(),
  },
}));

vi.mock("@fastify/helmet", () => ({
  default: mocks.fastifyHelmet,
}));

vi.mock("@fastify/jwt", () => ({
  default: mocks.fastifyJwt,
}));

vi.mock("@fastify/rate-limit", () => ({
  default: mocks.fastifyRateLimit,
}));

vi.mock("../../src/config/routes", () => mocks.routes);

import {
  registerApiRoutes,
  registerInfrastructure,
} from "../../src/utils/appBootstrap";

function makeApp() {
  return {
    register: vi.fn().mockResolvedValue(undefined),
  };
}

describe("appBootstrap", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("registers security, rate limit and JWT plugins", async () => {
    const app = makeApp();

    await registerInfrastructure(app as any, {
      jwtSecret: "secret",
      jwtAccessTtl: "14d",
    });

    expect(app.register).toHaveBeenNthCalledWith(
      1,
      mocks.fastifyHelmet,
      expect.objectContaining({
        contentSecurityPolicy: false,
        frameguard: { action: "deny" },
      }),
    );
    expect(app.register).toHaveBeenNthCalledWith(
      2,
      mocks.fastifyRateLimit,
      expect.objectContaining({
        global: true,
        max: 120,
        timeWindow: "1 minute",
      }),
    );
    expect(app.register).toHaveBeenNthCalledWith(3, mocks.fastifyJwt, {
      secret: "secret",
      sign: { expiresIn: "14d" },
    });
  });

  it("registers all API route groups with the configured prefix", async () => {
    const app = makeApp();

    await registerApiRoutes(app as any, "/api/test");

    expect(app.register).toHaveBeenCalledTimes(8);
    expect(app.register).toHaveBeenNthCalledWith(1, mocks.routes.health, {
      prefix: "/api/test",
    });
    expect(app.register).toHaveBeenNthCalledWith(2, mocks.routes.authRoutes, {
      prefix: "/api/test",
    });
    expect(app.register).toHaveBeenNthCalledWith(8, mocks.routes.accountRoutes, {
      prefix: "/api/test",
    });
  });
});
