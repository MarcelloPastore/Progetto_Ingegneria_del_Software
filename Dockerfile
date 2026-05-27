FROM node:20-bookworm-slim AS build
WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm --mount=type=cache,target=/root/.cache npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY tsconfig.json index.ts prisma.config.ts eslint.config.ts vitest.config.ts ./
COPY src ./src

RUN npm run build

FROM node:20-bookworm-slim
WORKDIR /app
ARG PORT=2310
ENV NODE_ENV=production
ENV PORT=${PORT}

RUN apt-get update -y \
  && apt-get install -y openssl \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 appgroup \
  && useradd -u 10001 -g appgroup -m -d /app -s /usr/sbin/nologin appuser

COPY --from=build /app/package.json ./package.json
COPY --from=build /app/package-lock.json ./package-lock.json
COPY --from=build /app/node_modules ./node_modules
RUN npm prune --omit=dev

COPY --from=build /app/dist ./dist

RUN chown -R appuser:appgroup /app

ENV PATH="/app/node_modules/.bin:$PATH"

USER appuser

EXPOSE ${PORT}
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=3 \
  CMD node -e "const http=require('node:http'); const port=process.env.PORT||2310; const req=http.get('http://127.0.0.1:'+port+'/api/v1/health',(res)=>process.exit(res.statusCode===200?0:1)); req.on('error',()=>process.exit(1)); req.setTimeout(2000,()=>{ req.destroy(); process.exit(1); });"

ENTRYPOINT ["node", "dist/index.js"]

