import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../../src/config/db", () => ({
  prisma: {},
}));

import {
  accountRoutes,
  authRoutes,
  casaRoutes,
  health,
  problemiRoutes,
  scadenzeRoutes,
  speseRoutes,
  turniRoutes,
} from "../../src/config/routes";

type RegisteredRoute = {
  method: string;
  path: string;
  handler: unknown;
  options?: unknown;
};

function createFakeApp() {
  const routes: RegisteredRoute[] = [];
  const hooks: Array<{ name: string; handler: unknown }> = [];

  const registerRoute = (method: string) =>
    vi.fn((path: string, optionsOrHandler?: unknown, maybeHandler?: unknown) => {
      const hasOptions = maybeHandler !== undefined;
      routes.push({
        method,
        path,
        options: hasOptions ? optionsOrHandler : undefined,
        handler: hasOptions ? maybeHandler : optionsOrHandler,
      });
    });

  return {
    routes,
    hooks,
    app: {
      addHook: vi.fn((name: string, handler: unknown) => {
        hooks.push({ name, handler });
      }),
      delete: registerRoute("DELETE"),
      get: registerRoute("GET"),
      patch: registerRoute("PATCH"),
      post: registerRoute("POST"),
      put: registerRoute("PUT"),
    } as any,
  };
}

describe("route registration", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("registers health, auth, casa, spese, turni, problemi, scadenze and account routes", () => {
    const { app, routes, hooks } = createFakeApp();

    health(app);
    authRoutes(app);
    casaRoutes(app);
    speseRoutes(app);
    turniRoutes(app);
    problemiRoutes(app);
    scadenzeRoutes(app);
    accountRoutes(app);

    expect(routes).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ method: "GET", path: "/health" }),
        expect.objectContaining({ method: "POST", path: "/auth/register" }),
        expect.objectContaining({ method: "POST", path: "/auth/login" }),
        expect.objectContaining({
          method: "POST",
          path: "/auth/recupera-password",
        }),
        expect.objectContaining({
          method: "POST",
          path: "/auth/verifica-codice-recupero",
        }),
        expect.objectContaining({
          method: "POST",
          path: "/auth/reset-password",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/auth/verifica-email",
        }),
        expect.objectContaining({ method: "POST", path: "/case" }),
        expect.objectContaining({ method: "GET", path: "/case" }),
        expect.objectContaining({ method: "GET", path: "/case/:idCasa" }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/inquilini",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/spese",
        }),
        expect.objectContaining({
          method: "POST",
          path: "/case/:idCasa/spese",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/saldo",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/turni",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/turni/oggi",
        }),
        expect.objectContaining({
          method: "POST",
          path: "/case/:idCasa/turni/:idTurno/completa",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/problemi",
        }),
        expect.objectContaining({
          method: "PATCH",
          path: "/case/:idCasa/problemi/:idProblema/stato",
        }),
        expect.objectContaining({
          method: "GET",
          path: "/case/:idCasa/scadenze",
        }),
        expect.objectContaining({
          method: "PATCH",
          path: "/case/:idCasa/scadenze/:idScadenza/ricorrenza",
        }),
        expect.objectContaining({ method: "GET", path: "/account" }),
        expect.objectContaining({
          method: "PATCH",
          path: "/account/username",
        }),
      ]),
    );

    expect(routes.length).toBeGreaterThanOrEqual(50);
    expect(hooks).toHaveLength(6);
    expect(hooks.every((hook) => hook.name === "onRequest")).toBe(true);

    const healthRoute = routes.find((route) => route.path === "/health");
    expect((healthRoute?.handler as () => unknown)()).toEqual({ status: "ok" });
  });
});
