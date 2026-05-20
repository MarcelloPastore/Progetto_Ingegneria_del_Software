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
    throw new ForbiddenError("");
  }
}

export function requireRole(role: Ruolo) {
  return async (req: FastifyRequest) => {
    checkRole(req.user?.ruoloCasa, role);
  };
}
