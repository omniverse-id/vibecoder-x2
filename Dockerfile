# ==================================
# Stage 1: Build Stage
# Menggunakan image Node.js penuh untuk kompilasi dan instalasi
# ==================================
FROM docker.m.daocloud.io/library/node:20.18 AS builder

WORKDIR /app

# 1. Copy config pnpm/npm dan dependencies
# Ini memungkinkan caching layer jika dependencies tidak berubah
COPY apps/we-dev-next/package.json ./
COPY apps/we-dev-next/pnpm-lock.yaml ./

# 2. Install dependencies
# Mengatur mirror dan menginstal pnpm secara global, lalu menjalankan pnpm install
RUN npm config set registry https://registry.npmmirror.com/ && \
    npm install -g pnpm && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm config set strict-ssl false && \
    pnpm install

# 3. Copy source code
# Salin seluruh source code aplikasi ke builder
COPY apps/we-dev-next/ ./

# 4. Run Build
# Jalankan build Next.js. Ini akan menghasilkan folder .next/
RUN pnpm build

# ==================================
# Stage 2: Production Stage
# Menggunakan image yang lebih ramping (slim) untuk environment runtime
# Hanya menyalin file yang dibutuhkan untuk menjalankan aplikasi
# ==================================
FROM docker.m.daocloud.io/library/node:20.18-slim AS runner

# Set Environment Variables (penting untuk runtime)
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# 1. Copy output build dari Stage 1
# Asumsi kamu TIDAK menggunakan output: 'standalone' di next.config.js
# Jika kamu menggunakan 'standalone', ganti baris copy di bawah ini
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

# 2. Copy package.json dan install pnpm untuk menjalankan CMD
COPY apps/we-dev-next/package.json ./
RUN npm install -g pnpm

# PENTING: Jika kamu menggunakan `output: 'standalone'` di next.config.js,
# ganti langkah copy di atas dengan yang berikut (ini lebih disarankan):
# COPY --from=builder /app/.next/standalone ./
# COPY --from=builder /app/.next/static ./.next/static
# COPY --from=builder /app/public ./public


EXPOSE 3000

# 3. Startup Command
CMD ["pnpm", "start"]
