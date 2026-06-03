# Multi-stage build keeps the runtime image small and makes the build
# failure mode obvious — the `test -f dist/main.js` line aborts the
# build immediately if nest build silently produced nothing, instead
# of letting the runtime crash with "Cannot find module".
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
# --legacy-peer-deps avoids the @nestjs/* peer-dep conflicts that can
# trip npm 10 inside the container even when the host install passes.
RUN npm install --legacy-peer-deps --no-audit --no-fund
COPY . .
RUN npm run build && test -f dist/main.js

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm install --omit=dev --legacy-peer-deps --no-audit --no-fund
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/main.js"]
