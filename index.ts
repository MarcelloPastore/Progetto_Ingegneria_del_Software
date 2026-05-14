import 'dotenv/config';
import Fastify from 'fastify';
import { connectDB } from './src/config/db';
import { authRoutes, health, debugRoutes } from './src/config/routes';
import fastifyJwt from '@fastify/jwt';
import fastifyHelmet from '@fastify/helmet';
import fastifyRateLimit from '@fastify/rate-limit';

const app = Fastify({ logger: true, bodyLimit: 1_048_576 });
const isProduction = process.env.NODE_ENV === 'production';
const jwtSecret = process.env.JWT_SECRET;

(async () => {
    try {
        if (!jwtSecret) {
            throw new Error('Variabile d\'ambiente JWT_SECRET mancante');
        }

        await connectDB();

        app.register(fastifyHelmet, {
            // Backend API per client mobile/web: hardening header senza CSP HTML.
            contentSecurityPolicy: false,
            crossOriginEmbedderPolicy: false,
            crossOriginResourcePolicy: false,
            frameguard: { action: 'deny' },
            referrerPolicy: { policy: 'no-referrer' },
            hsts: isProduction
                ? {
                    maxAge: 15552000,
                    includeSubDomains: true,
                    preload: false
                }
                : false
        });

        app.register(fastifyRateLimit, {
            global: true,
            max: 120,
            timeWindow: '1 minute'
        });

        app.register(fastifyJwt, {
            secret: jwtSecret,
            sign: { expiresIn: process.env.JWT_ACCESS_TTL ?? '15m' }
        });

        app.register(health, { prefix: '/api/v1' });
        app.register(authRoutes, { prefix: '/api/v1' });
        app.register(debugRoutes, { prefix: '/api/v1' });
        await app.listen({ port: 2310 });
    } catch (err) {
        console.error('Errore durante l\'avvio:', err);
        process.exit(1);
    }
})();
