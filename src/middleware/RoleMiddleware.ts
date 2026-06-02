import { Ruolo } from "@prisma/client";
import { FastifyRequest } from "fastify";
import { ForbiddenError } from "../errors/httpErrors";

function checkRole(ruolo: Ruolo | undefined, role: Ruolo) {
  const roleHierarchy: Record<Ruolo, number> = {
    [Ruolo.Inquilino]: 1,
    [Ruolo.HomeAdmin]: 2,
    [Ruolo.SysAdmin]: 3,
  };

  const userLevel = ruolo ? roleHierarchy[ruolo] : 0;
  const requiredLevel = roleHierarchy[role];

  if (userLevel < requiredLevel) {
    throw new ForbiddenError("Ruolo insufficiente per questa azione.");
  }
}

function verifyCasa(req: FastifyRequest): Ruolo | undefined {
  const tokenCasa = req.user?.idCasa ?? null;
  const pathParams = req.params as Record<string, unknown> | undefined;
  const pathCasa =
    pathParams && typeof pathParams.idCasa === "string"
      ? pathParams.idCasa
      : undefined;

  if (pathCasa === undefined) {
    return req.user.ruoloCasa;
  }

  if (!tokenCasa) {
    throw new ForbiddenError("L'utente non ha una casa selezionata nel token.");
  }

  if (tokenCasa !== pathCasa) {
    throw new ForbiddenError("Accesso alla casa non autorizzato.");
  }

  return req.user.ruoloCasa;
}

export function requireRole(role: Ruolo) {
  return (req: FastifyRequest) => {
    const ruoloCasa = verifyCasa(req);
    checkRole(ruoloCasa, role);
  };
}
