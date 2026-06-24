import { Ruolo } from "@prisma/client";
import { FastifyRequest, FastifyReply } from "fastify";
import { ForbiddenError, RoleOutdatedError } from "../errors/httpErrors";
import { sendErrorReply } from "../utils/errorReply";
import { prisma } from "../config/db";

const ROLE_HIERARCHY: Record<Ruolo, number> = {
  [Ruolo.Inquilino]: 1,
  [Ruolo.HomeAdmin]: 2,
  [Ruolo.SysAdmin]: 3,
};

function checkRole(ruolo: Ruolo | undefined, role: Ruolo) {
  const userLevel = ruolo ? (ROLE_HIERARCHY[ruolo] ?? 0) : 0;
  const requiredLevel = ROLE_HIERARCHY[role];

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

/**
 * Verifica direttamente nel DB che l'utente sia membro della casa
 * e abbia il ruolo richiesto. Se il token afferma un ruolo sufficiente
 * ma il DB non lo conferma, il token è obsoleto: si restituisce
 * RoleOutdatedError per forzare il frontend a fare nuova selectCasa.
 */
async function verifyDbRoleForAdmin(
  req: FastifyRequest,
  requiredRole: Ruolo,
): Promise<void> {
  const { idUtente, idCasa } = req.user;
  if (!idCasa) return;

  const membro = await prisma.membroCasa.findFirst({
    where: { idCasa, idUtente },
    select: { ruolo: true },
  });

  const dbLevel = membro ? (ROLE_HIERARCHY[membro.ruolo] ?? 0) : 0;
  if (dbLevel < ROLE_HIERARCHY[requiredRole]) {
    throw new RoleOutdatedError();
  }
}

export function requireRole(role: Ruolo) {
  return async (req: FastifyRequest, rep: FastifyReply) => {
    try {
      const ruoloCasa = verifyCasa(req);
      checkRole(ruoloCasa, role);
      if (ROLE_HIERARCHY[role] >= ROLE_HIERARCHY[Ruolo.HomeAdmin]) {
        await verifyDbRoleForAdmin(req, role);
      }
    } catch (err) {
      await sendErrorReply(rep, err);
    }
  };
}
