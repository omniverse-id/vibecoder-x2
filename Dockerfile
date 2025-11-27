ARG THIRD_API_URL
ARG THIRD_API_KEY
ARG APP_BASE_URL
ARG JWT_SECRET
ARG SERVER_ADDRESS

FROM docker.m.daocloud.io/library/node:20.18 AS builder

WORKDIR /app

# Konversi ARG menjadi ENV
ENV THIRD_API_URL=$THIRD_API_URL
ENV THIRD_API_KEY=$THIRD_API_KEY
ENV APP_BASE_URL=$APP_BASE_URL
ENV JWT_SECRET=$JWT_SECRET
ENV SERVER_ADDRESS=$SERVER_ADDRESS

# Copy config dan dependencies
COPY apps/we-dev-next/package.json ./
COPY apps/we-dev-next/pnpm-lock.yaml ./

# Install dependencies (Node_modules terbuat di sini)
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

# Environment Variables untuk Runtime
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# Copy output build dari Stage 1
COPY --from=builder /app/.next ./.next
# Folder public dihilangkan, sesuai permintaan sebelumnya

# FIX: Menyalin folder node_modules dari builder (tempat next dan depedensi lain berada)
COPY --from=builder /app/node_modules ./node_modules 

# Setup pnpm untuk Runner Stage
COPY apps/we-dev-next/package.json ./
RUN npm install -g pnpm

EXPOSE 3000

# Start Command
CMD ["pnpm", "start"]
