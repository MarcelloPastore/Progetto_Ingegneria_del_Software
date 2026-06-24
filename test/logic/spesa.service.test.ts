/**
 * LOGIC TESTS — SpesaService
 *
 * Focus sui flussi principali “happy path” e sulle trasformazioni di dominio:
 * - creazione spesa (quote calcolate e anticipatario)
 * - pagamento quota
 * - calcolo saldo/credito/debito
 */
import { Ruolo } from "@prisma/client";
import { describe, it, expect, vi, beforeEach } from "vitest";

const mocks = vi.hoisted(() => ({
  findMembroCasaByCasaAndUtenteOrThrow: vi.fn(),
  createSpesa: vi.fn(),
  updateSpesa: vi.fn(),
  findSpesaByIdOrThrow: vi.fn(),
  findSpeseByCasa: vi.fn(),
  deleteSpesa: vi.fn(),
  findQuoteBySpesa: vi.fn(),
  findQuoteByIdOrThrow: vi.fn(),
  markQuotaPagata: vi.fn(),
  saldaQuoteVersoCreditori: vi.fn(),
  sumCredito: vi.fn(),
  sumDebito: vi.fn(),
  sumCreditoVersoUtente: vi.fn(),
  sumDebitoVersoUtente: vi.fn(),
}));

vi.mock("../../src/repository/CasaRepository", () => ({
  CasaRepository: class {
    constructor() {
      Object.assign(this as any, {
        findMembroCasaByCasaAndUtenteOrThrow:
          mocks.findMembroCasaByCasaAndUtenteOrThrow,
      });
    }
  },
}));

vi.mock("../../src/repository/SpesaRepository", () => ({
  SpesaRepository: class {
    constructor() {
      Object.assign(this as any, {
        createSpesa: mocks.createSpesa,
        updateSpesa: mocks.updateSpesa,
        findSpesaByIdOrThrow: mocks.findSpesaByIdOrThrow,
        findSpeseByCasa: mocks.findSpeseByCasa,
        deleteSpesa: mocks.deleteSpesa,
        findQuoteBySpesa: mocks.findQuoteBySpesa,
        findQuoteByIdOrThrow: mocks.findQuoteByIdOrThrow,
        markQuotaPagata: mocks.markQuotaPagata,
        saldaQuoteVersoCreditori: mocks.saldaQuoteVersoCreditori,
        sumCredito: mocks.sumCredito,
        sumDebito: mocks.sumDebito,
        sumCreditoVersoUtente: mocks.sumCreditoVersoUtente,
        sumDebitoVersoUtente: mocks.sumDebitoVersoUtente,
      });
    }
  },
}));

import { SpesaService } from "../../src/service/SpesaService";

describe("SpesaService", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const baseSpesa = {
    id: "s1",
    idCasa: "c1",
    descrizione: "Spesa",
    importo: 10,
    owner: "u1",
    ownerRel: { id: "u1", username: "mario" },
    anticipataDa: "u1",
    anticipataDaRel: { id: "u1", username: "mario" },
    partecipanti: ["u1", "u2"],
    partecipantiRel: [
      { id: "u1", username: "mario" },
      { id: "u2", username: "luigi" },
    ],
    quote: [],
    scadenzaRel: null,
    idScadenza: "sc1",
    dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
  };

  it("addSpesa computes quotes with cent rounding and marks anticipatario as paid", async () => {
    // 10.00 split among 3 => 3.34 + 3.33 + 3.33 (sum 10.00)
    const now = new Date("2026-05-18T10:30:00.000Z");
    vi.setSystemTime(now);

    const created = {
      id: "s1",
      descrizione: "Spesa",
      importo: 10,
      dataCreazione: now,
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: "u1",
      anticipataDaRel: { id: "u1", username: "mario" },
      quote: [],
      partecipantiRel: [
        { id: "u1", username: "mario" },
        { id: "u2", username: "luigi" },
        { id: "u3", username: "anna" },
      ],
      scadenzaRel: null,
    };

    mocks.createSpesa.mockResolvedValue(created);

    const service = new SpesaService();
    await service.addSpesa(
      "c1",
      {
        descrizione: "Spesa",
        importo: 10,
        partecipanti: ["u1", "u2", "u3"],
        anticipataDa: "u1",
        isRicorrente: false,
      },
      "u1",
    );

    const [arg] = mocks.createSpesa.mock.calls[0] as [
      {
        quote: Array<{ idUtente: string; quota: number; dataPagamento?: Date }>;
      },
    ];

    expect(arg.quote).toHaveLength(3);

    const sum = arg.quote.reduce((acc, q) => acc + q.quota, 0);
    expect(sum).toBeCloseTo(10, 6);

    const ownerQuota = arg.quote.find((q) => q.idUtente === "u1");
    expect(ownerQuota?.dataPagamento).toBeInstanceOf(Date);

    vi.useRealTimers();
  });

  it("pagaQuota marks quota as paid and returns dto", async () => {
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
        anticipataDaRel: { id: "u1", username: "mario" },
      },
    });

    mocks.markQuotaPagata.mockResolvedValue({
      id: "q1",
      idUtente: "u2",
      quota: 5,
      dataPagamento: new Date("2026-05-19T10:00:00.000Z"),
      utenteRel: { id: "u2", username: "luigi" },
      spesaRel: {
        id: "s1",
        descrizione: "Spesa",
        importo: 10,
        anticipataDa: "u1",
        anticipataDaRel: { id: "u1", username: "mario" },
      },
    });

    const service = new SpesaService();
    const dto = await service.pagaQuota("c1", "s1", "q1", "u2");

    expect(mocks.markQuotaPagata).toHaveBeenCalledWith("q1");
    expect(dto.utente).toEqual({ id: "u2", username: "luigi" });
    expect(dto.dataPagamento).toBe("2026-05-19T10:00:00.000Z");
  });

  it("getSaldo returns credito - debito", async () => {
    mocks.sumCredito.mockResolvedValue(12);
    mocks.sumDebito.mockResolvedValue(7);

    const service = new SpesaService();
    const result = await service.getSaldo("c1", "u1");

    expect(result).toEqual({ saldo: 5 });
  });

  it("returns expense lists, single expenses and balance projections", async () => {
    mocks.findSpeseByCasa.mockResolvedValue([baseSpesa]);
    mocks.findSpesaByIdOrThrow.mockResolvedValue(baseSpesa);
    mocks.sumCredito.mockResolvedValue(12);
    mocks.sumDebito.mockResolvedValue(7);
    mocks.sumCreditoVersoUtente.mockResolvedValue(4);
    mocks.sumDebitoVersoUtente.mockResolvedValue(3);
    mocks.saldaQuoteVersoCreditori.mockResolvedValue(1);

    const service = new SpesaService();

    await expect(service.getAllSpese("c1")).resolves.toHaveLength(1);
    await expect(service.getSpesa("c1", "s1")).resolves.toEqual(
      expect.objectContaining({ id: "s1", descrizione: "Spesa" }),
    );
    await expect(service.getCredito("c1", "u1")).resolves.toEqual({
      credito: 12,
    });
    await expect(service.getDebito("c1", "u1")).resolves.toEqual({ debito: 7 });
    await expect(
      service.getCreditoVersoUtente("c1", "u2", "u1"),
    ).resolves.toEqual({ credito: 4 });
    await expect(
      service.getDebitoVersoUtente("c1", "u2", "u1"),
    ).resolves.toEqual({ debito: 3 });
    await expect(
      service.pareggiaConti("c1", "u1", { idUtentiCreditori: ["u2"] }),
    ).resolves.toBeUndefined();

    expect(mocks.saldaQuoteVersoCreditori).toHaveBeenCalledWith("c1", "u1", [
      "u2",
    ]);
  });

  it("updateSpesa recomputes quote when importo changes (sum matches new importo)", async () => {
    const existing = {
      id: "s1",
      idCasa: "c1",
      descrizione: "Spesa",
      importo: 10,
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: "u1",
      anticipataDaRel: { id: "u1", username: "mario" },
      partecipanti: ["u1", "u2", "u3"],
      partecipantiRel: [
        { id: "u1", username: "mario" },
        { id: "u2", username: "luigi" },
        { id: "u3", username: "anna" },
      ],
      scadenzaRel: null,
      quote: [
        {
          id: "q1",
          quota: 3.34,
          idUtente: "u1",
          utenteRel: { id: "u1", username: "mario" },
          dataPagamento: new Date(),
        },
        {
          id: "q2",
          quota: 3.33,
          idUtente: "u2",
          utenteRel: { id: "u2", username: "luigi" },
          dataPagamento: null,
        },
        {
          id: "q3",
          quota: 3.33,
          idUtente: "u3",
          utenteRel: { id: "u3", username: "anna" },
          dataPagamento: null,
        },
      ],
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
    };

    mocks.findSpesaByIdOrThrow.mockResolvedValue(existing);
    mocks.updateSpesa.mockResolvedValue(existing);

    const service = new SpesaService();
    await service.updateSpesa("c1", "s1", { importo: 10.01 }, "u1");

    const [, , , quoteArg] = mocks.updateSpesa.mock.calls[0] as [
      string,
      string,
      unknown,
      (
        | Array<{ idUtente: string; quota: number; dataPagamento?: Date }>
        | undefined
      ),
    ];

    expect(Array.isArray(quoteArg)).toBe(true);
    expect(quoteArg).toHaveLength(3);

    const sum = (quoteArg ?? []).reduce((acc, q) => acc + q.quota, 0);
    expect(sum).toBeCloseTo(10.01, 6);

    // L'anticipatario deve risultare pagato al ricalcolo quote
    const ownerQuota = (quoteArg ?? []).find((q) => q.idUtente === "u1");
    expect(ownerQuota?.dataPagamento).toBeInstanceOf(Date);
  });

  it("updateSpesa upserts scadenza when dataScadenza is provided (nome = 'Spesa: <descrizione>')", async () => {
    const existing = {
      id: "s2",
      idCasa: "c1",
      descrizione: "Internet",
      importo: 30,
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: null,
      partecipanti: ["u1", "u2"],
      partecipantiRel: [
        { id: "u1", username: "mario" },
        { id: "u2", username: "luigi" },
      ],
      scadenzaRel: null,
      quote: [],
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
    };

    mocks.findSpesaByIdOrThrow.mockResolvedValue(existing);
    mocks.updateSpesa.mockResolvedValue(existing);

    const service = new SpesaService();
    await service.updateSpesa(
      "c1",
      "s2",
      {
        descrizione: "Internet casa",
        dataScadenza: "2026-06-01",
        isRicorrente: true,
        cadenzaGiorni: 30,
      },
      "u1",
    );

    const [, , , , scadenzaArg] = mocks.updateSpesa.mock.calls[0] as [
      string,
      string,
      unknown,
      unknown,
      (
        | {
            nome: string;
            descrizione: string;
            dataScadenza: Date;
            isRicorrente: boolean;
            cadenzaGiorni?: number | null;
          }
        | undefined
      ),
    ];

    expect(scadenzaArg).toBeDefined();
    expect(scadenzaArg?.nome).toBe("Spesa: Internet casa");
    expect(scadenzaArg?.descrizione).toBe("Internet casa");
    expect(scadenzaArg?.dataScadenza).toBeInstanceOf(Date);
    expect(
      scadenzaArg?.dataScadenza.toISOString().startsWith("2026-06-01"),
    ).toBe(true);
    expect(scadenzaArg?.isRicorrente).toBe(true);
    expect(scadenzaArg?.cadenzaGiorni).toBe(30);
  });

  it("updateSpesa does not create scadenza when only isRicorrente/cadenzaGiorni are provided and no scadenza exists", async () => {
    const existing = {
      id: "s3",
      idCasa: "c1",
      descrizione: "Internet",
      importo: 30,
      owner: "u1",
      ownerRel: { id: "u1", username: "mario" },
      anticipataDa: null,
      partecipanti: ["u1", "u2"],
      partecipantiRel: [
        { id: "u1", username: "mario" },
        { id: "u2", username: "luigi" },
      ],
      scadenzaRel: null,
      quote: [],
      dataCreazione: new Date("2026-05-18T10:30:00.000Z"),
    };

    mocks.findSpesaByIdOrThrow.mockResolvedValue(existing);
    mocks.updateSpesa.mockResolvedValue(existing);

    const service = new SpesaService();
    await service.updateSpesa(
      "c1",
      "s3",
      {
        isRicorrente: true,
        cadenzaGiorni: 30,
      },
      "u1",
    );

    const [, , , , scadenzaArg] = mocks.updateSpesa.mock.calls[0] as [
      string,
      string,
      unknown,
      unknown,
      unknown,
    ];

    expect(scadenzaArg).toBeUndefined();
  });

  it("deleteSpesa lets admins remove expenses and blocks paid expenses for non admins", async () => {
    const paidByTenant = {
      ...baseSpesa,
      quote: [
        {
          id: "q1",
          quota: 5,
          idUtente: "u2",
          utenteRel: { id: "u2", username: "luigi" },
          dataPagamento: new Date("2026-05-19T10:00:00.000Z"),
        },
      ],
    };

    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValueOnce({
      ruolo: Ruolo.HomeAdmin,
    });
    mocks.findSpesaByIdOrThrow.mockResolvedValueOnce(paidByTenant);
    mocks.deleteSpesa.mockResolvedValue(undefined);

    const service = new SpesaService();
    await expect(
      service.deleteSpesa("c1", "s1", "admin"),
    ).resolves.toBeUndefined();
    expect(mocks.deleteSpesa).toHaveBeenCalledWith("c1", "s1", "sc1");

    mocks.findMembroCasaByCasaAndUtenteOrThrow.mockResolvedValueOnce({
      ruolo: Ruolo.Inquilino,
    });
    mocks.findSpesaByIdOrThrow.mockResolvedValueOnce(paidByTenant);

    await expect(service.deleteSpesa("c1", "s1", "u1")).rejects.toThrow(
      "pagamenti gia effettuati",
    );
  });

  it("getQuota and pagaQuota enforce quota ownership and payment state", async () => {
    const quota = {
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
        anticipataDaRel: { id: "u1", username: "mario" },
      },
    };

    mocks.findQuoteByIdOrThrow.mockResolvedValueOnce(quota);
    const service = new SpesaService();

    await expect(service.getQuota("c1", "s1", "q1", "u2")).resolves.toEqual(
      expect.objectContaining({ id: "q1" }),
    );

    mocks.findQuoteByIdOrThrow.mockResolvedValueOnce(quota);
    await expect(service.getQuota("c1", "s1", "q1", "u1")).rejects.toThrow(
      "visualizzare questa quota",
    );

    mocks.findQuoteByIdOrThrow.mockResolvedValueOnce({
      ...quota,
      idUtente: "u2",
    });
    await expect(service.pagaQuota("c1", "s1", "q1", "u1")).rejects.toThrow(
      "Solo il debitore",
    );

    mocks.findQuoteByIdOrThrow.mockResolvedValueOnce({
      ...quota,
      dataPagamento: new Date("2026-05-19T10:00:00.000Z"),
    });
    await expect(service.pagaQuota("c1", "s1", "q1", "u2")).rejects.toThrow(
      "Quota gia saldata",
    );
  });
});
