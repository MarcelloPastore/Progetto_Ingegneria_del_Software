import { FastifyRequest, FastifyReply } from 'fastify';
import { SpeseService } from "../service/SpeseService";

type IdCasaParams = { idCasa: string };
type IdCasaSpesaParams = { idCasa: string; id: string };
type IdCasaSpesaQuotaParams = { idCasa: string; id: string; idQuota: string };

// DTO
interface CreateSpesaBody {
    descrizione: string;
    importo: number;
    dataSpesa: string;
    pagatoDa: string;
    quote?: { idUtente: string; importo: number }[];
}

// DTO
interface UpdateSpesaBody {
    descrizione?: string;
    importo?: number;
    dataSpesa?: string;
}

export class SpeseController {
    // Verificare se necessario
    private readonly service = new SpeseService();

    getAllSpese = async (
        req: FastifyRequest<{ Params: IdCasaParams }>,
        reply: FastifyReply,
    ) => {
        const { idCasa } = req.params;
        const { idUtente } = req.user;
        // TODO: this.service.getAll(idCasa, idUtente)
        return reply.send({ idCasa, idUtente, spese: [] });
    };

}
