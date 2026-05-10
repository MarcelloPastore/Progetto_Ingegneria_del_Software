import Fastify from 'fastify';
import { connectDB } from './src/config/db';
import {authRoutes, health, speseRoutes} from "./src/config/routes";

const app = Fastify({ logger: true });

async function main() {
    await connectDB();

    app.register(health, {prefix: '/api/v1'});
    app.register(authRoutes, {prefix: '/api/v1'});
    app.register(speseRoutes, {prefix: '/api/v1'});

    await app.listen({ port: 231099 });
}