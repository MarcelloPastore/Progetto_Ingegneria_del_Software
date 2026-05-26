import { Ruolo } from "@prisma/client";
import { FastifyRequest } from "fastify";
import { prisma } from "../config/db";
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

async function resolveRuoloCasa(
  req: FastifyRequest,
): Promise<Ruolo | undefined> {
  if (req.user?.ruoloCasa) {
    return req.user.ruoloCasa as Ruolo;
  }

  const params = req.params as { idCasa?: string } | undefined;
  const idCasa = params?.idCasa;

  if (!req.user?.idUtente || !idCasa) {
    return undefined;
  }

  const membro = await prisma.membroCasa.findFirst({
    where: { idCasa, idUtente: req.user.idUtente },
    select: { ruolo: true },
  });

  if (!membro) {
    return undefined;
  }

  req.user.ruoloCasa = membro.ruolo;
  return membro.ruolo;
}

export function requireRole(role: Ruolo) {
  return async (req: FastifyRequest) => {
    const ruoloCasa = await resolveRuoloCasa(req);
    checkRole(ruoloCasa, role);
  };
}
