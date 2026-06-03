# NOTE: this image expects `dist/` to be pre-built on the host before
# `docker-compose up --build`. Run, from the repo root:
#
#     cd backend && npm install --legacy-peer-deps && npm run build
#
# We do NOT run `nest build` inside the container — it exits 1
# silently on node:22-alpine (likely OOM during typecheck) and the
# original "test -f dist/main.js" guard rightly aborted the build.
#
# Native deps (bcrypt) still need to be compiled inside the image so
# they match linux/musl; that's what the `npm ci --omit=dev` below
# does. We intentionally do NOT copy node_modules from the host —
# Windows/macOS .node binaries would crash at runtime.
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production

# Build-time toolchain for native bindings (bcrypt). Removed after
# npm finishes so the runtime image stays slim.
RUN apk add --no-cache --virtual .build-deps python3 make g++

COPY package*.json ./
RUN npm ci --omit=dev --legacy-peer-deps --no-audit --no-fund \
 && apk del .build-deps

# Pre-built JS from the host.
COPY dist ./dist

EXPOSE 3000
# tsc preserves the source tree because migrations/ lives outside
# src/, so the real entrypoint is dist/src/main.js (not dist/main.js).
CMD ["node", "dist/src/main.js"]
