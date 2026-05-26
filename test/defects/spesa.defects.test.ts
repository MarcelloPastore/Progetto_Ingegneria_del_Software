/**
 * DEFECT / REGRESSION TESTS — SpesaService
 *
 * Scopo:
 * - autorizzazioni e vincoli che non devono cambiare (Forbidden/Conflict)
 */
import { describe, it, expect, vi, beforeEach } from "vitest";
import { ConflictError, ForbiddenError } from "../../src/errors/httpErrors";

const mocks = vi.hoisted(() => ({
  createSpesa: vi.fn(),
  updateSpesa: vi.fn(),
  findSpesaByIdOrThrow: vi.fn(),
  deleteSpesa: vi.fn(),
  findQuoteByIdOrThrow: vi.fn(),
  markQuotaPagata: vi.fn(),
}));

vi.mock("../../src/repository/SpesaRepository", () => ({
  SpesaRepository: class {
    constructor() {
      Object.assign(this as any, {
        createSpesa: mocks.createSpesa,
        updateSpesa: mocks.updateSpesa,
        findSpesaByIdOrThrow: mocks.findSpesaByIdOrThrow,
        deleteSpesa: mocks.deleteSpesa,
        findQuoteByIdOrThrow: mocks.findQuoteByIdOrThrow,
        markQuotaPagata: mocks.markQuotaPagata,
      });
    }
  },
}));

import { SpesaService } from "../../src/service/SpesaService";

describe("SpesaService - defects", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("addSpesa rejects duplicate partecipanti", async () => {
    const service = new SpesaService();

    await expect(
      service.addSpesa(
        "c1",
        {
          descrizione: "Spesa",
          importo: 10,
          partecipanti: ["u1", "u1"],
          anticipataDa: "u1",
          isRicorrente: false,
        },
        "u1",
      ),
    ).rejects.toBeInstanceOf(ConflictError);
  });

  it("addSpesa rejects anticipataDa different from authenticated user", async () => {
    const service = new SpesaService();

    await expect(
      service.addSpesa(
        "c1",
        {
          descrizione: "Spesa",
          importo: 10,
          partecipanti: ["u1", "u2"],
          anticipataDa: "u2",
          isRicorrente: false,
        },
        "u1",
      ),
    ).rejects.toBeInstanceOf(ConflictError);
  });

  it("updateSpesa throws ForbiddenError when non-owner modifies", async () => {
    mocks.findSpesaByIdOrThrow.mockResolvedValue({
      id: "s1",
      idCasa: "c1",
      owner: "u1",
      anticipataDa: null,
      partecipanti: ["u1"],
      descrizione: "Spesa",
      importo: 10,
      quote: [],
      dataCreazione: new Date(),
    });

    const service = new SpesaService();

    await expect(
      service.updateSpesa("c1", "s1", { descrizione: "x" }, "u2"),
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it("pagaQuota throws ForbiddenError if caller is not debtor", async () => {
    mocks.findQuoteByIdOrThrow.mockResolvedValue({
      id: "q1",
      idUtente: "u2",
      quota: 5,
      dataPagamento: null,
      utenteRel: { id: "u2", username: "luigi" },
      spesaRel: {
        id: "s1",
        descrizione: "Spesa",
        importo: 10,
        anticipataDa: "u1",
      },
    });

    const service = new SpesaService();
    await expect(service.pagaQuota("c1", "s1", "q1", "u9")).rejects.toBeInstanceOf(
      ForbiddenError,
    );
  });

  it("pagaQuota throws ConflictError if quota already paid", async () => {
    mocks.findQuoteByIdOrThrow.mockResolvedValue({
      id: "q1",
      idUtente: "u2",
      quota: 5,
      dataPagamento: new Date(),
      utenteRel: { id: "u2", username: "luigi" },
      spesaRel: {
        id: "s1",
        descrizione: "Spesa",
        importo: 10,
        anticipataDa: "u1",
      },
    });

    const service = new SpesaService();
    await expect(service.pagaQuota("c1", "s1", "q1", "u2")).rejects.toBeInstanceOf(
      ConflictError,
    );
  });
});


