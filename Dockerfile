FROM node:24.16.0-trixie-slim AS build
WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
COPY prisma ./prisma/

RUN npm ci

RUN npx prisma generate

COPY tsconfig.json index.ts prisma.config.ts eslint.config.ts vitest.config.ts ./
COPY src ./src

RUN npm run build

RUN MONGODB_URI="mongodb://localhost:27017/placeholder" npx prisma generate

RUN npm prune --omit=dev

FROM node:24.16.0-trixie-slim
WORKDIR /app

ENV NODE_ENV=production

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/prisma ./prisma

EXPOSE 23109
CMD ["node", "dist/index.js"]