import Fastify from 'fastify';
import { connectDB } from './src/config/db';
import {authRoutes, casaRoutes, health, problemiRoutes, speseRoutes, turniRoutes} from "./src/config/routes";

const app = Fastify({ logger: true });

async function main() {
    await connectDB();

    app.register(health, {prefix: '/api/v1'});
    app.register(authRoutes, {prefix: '/api/v1'});
    app.register(speseRoutes, {prefix: '/api/v1'});
    app.register(casaRoutes, {prefix: '/api/v1'});
    app.register(turniRoutes, {prefix: '/api/v1'});
    app.register(problemiRoutes, {prefix: '/api/v1'});

    await app.listen({ port: 231099 });
}