import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  sumCredito: vi.fn(),
  sumDebito: vi.fn(),
}));

vi.mock("../src/repository/SpesaRepository", () => ({
  SpesaRepository: class {
    sumCredito = mocks.sumCredito;
    sumDebito = mocks.sumDebito;
  },
}));

import { SpesaService } from "../src/service/SpesaService";

describe("SpesaService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("restituisce un saldo negativo quando le quote non pagate superano i crediti", async () => {
    mocks.sumCredito.mockResolvedValue(0);
    mocks.sumDebito.mockResolvedValue(25.5);

    const service = new SpesaService();
    const result = await service.getSaldo("casa-1", "utente-debitore");

    expect(result).toEqual({ saldo: -25.5 });
    expect(mocks.sumCredito).toHaveBeenCalledWith("casa-1", "utente-debitore");
    expect(mocks.sumDebito).toHaveBeenCalledWith("casa-1", "utente-debitore");
  });
});
