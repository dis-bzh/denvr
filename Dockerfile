# Stage 1: install dependencies
FROM node:lts-alpine AS deps
WORKDIR /app
COPY ./nextjs/package*.json .
ARG NODE_ENV
ENV NODE_ENV $NODE_ENV
RUN npm install

# Stage 2: build
FROM node:lts-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY ./nextjs/src ./src
COPY ./nextjs/public ./public
COPY ./nextjs/package.json ./nextjs/next.config.ts ./
RUN npm run build

# Stage 3: run
FROM node:lts-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
CMD ["npm", "run", "start"]
