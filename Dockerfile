# ==================================
# 1. ARG untuk menerima dari Easypanel
# ==================================
ARG THIRD_API_URL
ARG THIRD_API_KEY
ARG APP_BASE_URL
ARG JWT_SECRET  # Tambahkan JWT_SECRET jika diperlukan di build time
ARG SERVER_ADDRESS # Tambahkan SERVER_ADDRESS jika diperlukan di build time

FROM docker.m.daocloud.io/library/node:20.18 AS builder

WORKDIR /app

# ==================================
# 2. KONVERSI ARG ke ENV
# Next.js/Node.js hanya bisa membaca ENV saat RUN pnpm build
# ==================================
ENV THIRD_API_URL=$THIRD_API_URL
ENV THIRD_API_KEY=$THIRD_API_KEY
ENV APP_BASE_URL=$APP_BASE_URL
ENV JWT_SECRET=$JWT_SECRET
ENV SERVER_ADDRESS=$SERVER_ADDRESS

# Lanjutan Build Stage
COPY apps/we-dev-next/package.json ./
COPY apps/we-dev-next/pnpm-lock.yaml ./

RUN npm config set registry https://registry.npmmirror.com/ && \
    npm install -g pnpm && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm config set strict-ssl false && \
    pnpm install

COPY apps/we-dev-next/ ./

RUN pnpm build

FROM docker.m.daocloud.io/library/node:20.18-slim AS runner

# Variabel ENV untuk Runtime (sudah benar)
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

COPY apps/we-dev-next/package.json ./
RUN npm install -g pnpm

EXPOSE 3000

CMD ["pnpm", "start"]
