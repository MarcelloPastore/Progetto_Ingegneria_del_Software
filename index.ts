import 'dotenv/config';
import Fastify from 'fastify';
import { connectDB } from './src/config/db';
import {
    getRequiredEnv,
    registerInfrastructure,
    registerApiRoutes
} from './src/utils/appBootstrap';

const app = Fastify({ logger: true, bodyLimit: 1_048_576 });

(async () => {
    try {
        const jwtSecret = getRequiredEnv('JWT_SECRET');

        await connectDB();
        await registerInfrastructure(app, { jwtSecret });
        await registerApiRoutes(app);
        await app.listen({ port: 2310 });
    } catch (err) {
        console.error('Errore durante l\'avvio:', err);
        process.exit(1);
    }
})();
