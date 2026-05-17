import Fastify from 'fastify';
import 'dotenv/config';
import { connectDB } from './src/config/db';
import {authRoutes, casaRoutes, health, problemiRoutes, speseRoutes, turniRoutes} from "./src/config/routes";

const app = Fastify({ logger: true });
const myPort = process.env.PORT ? Number(process.env.PORT) : 3000;

async function main() {
    await connectDB();

    app.register(health, {prefix: '/api/v1'});
    app.register(authRoutes, {prefix: '/api/v1'});
    app.register(speseRoutes, {prefix: '/api/v1'});
    app.register(casaRoutes, {prefix: '/api/v1'});
    app.register(turniRoutes, {prefix: '/api/v1'});
    app.register(problemiRoutes, {prefix: '/api/v1'});

    await app.listen({ port: myPort });
}

main().catch((err) => {
    app.log.error(err);
    process.exit(1);
});
