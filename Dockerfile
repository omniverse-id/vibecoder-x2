ARG THIRD_API_URL
ARG THIRD_API_KEY
ARG APP_BASE_URL
ARG JWT_SECRET
ARG SERVER_ADDRESS

FROM docker.m.daocloud.io/library/node:20.18 AS builder

WORKDIR /app

# FIX 1: Konversi ARG menjadi ENV untuk pnpm build
ENV THIRD_API_URL=$THIRD_API_URL
ENV THIRD_API_KEY=$THIRD_API_KEY
ENV APP_BASE_URL=$APP_BASE_URL
ENV JWT_SECRET=$JWT_SECRET
ENV SERVER_ADDRESS=$SERVER_ADDRESS

# Copy config dan dependencies
COPY apps/we-dev-next/package.json ./
COPY apps/we-dev-next/pnpm-lock.yaml ./

# Install dependencies
RUN npm config set registry https://registry.npmmirror.com/ && \
    npm install -g pnpm && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm config set strict-ssl false && \
    pnpm install

# Copy source code aplikasi
COPY apps/we-dev-next/ ./

# Run Build
RUN pnpm build

FROM docker.m.daocloud.io/library/node:20.18-slim AS runner

# FIX 2: Atur ke Port 80 sesuai log runtime Next.js
ENV NODE_ENV=production
ENV PORT=80

WORKDIR /app

# Copy output build dari Stage 1
COPY --from=builder /app/.next ./.next

# FIX 3: Menyalin node_modules agar perintah 'next' ditemukan
COPY --from=builder /app/node_modules ./node_modules 

# Setup pnpm untuk Runner Stage
COPY apps/we-dev-next/package.json ./
RUN npm install -g pnpm

# FIX 4: Expose Port 80
EXPOSE 80

# Start Command
CMD ["pnpm", "start"]
