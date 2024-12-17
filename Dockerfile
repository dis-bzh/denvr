# Stage 1: install dependencies
FROM node:22-alpine AS deps
WORKDIR /app
COPY my-app/package*.json ./
ARG NODE_ENV
ENV NODE_ENV $NODE_ENV
RUN npm install

# Stage 2: build
FROM node:22-alpine AS builder
WORKDIR /app
COPY ./my-app/ .
COPY --from=deps /app/node_modules ./node_modules
RUN npm run build

# Stage 3: run
FROM node:22-alpine
WORKDIR /app
COPY --chown=node:node --from=builder /app/.next ./.next
COPY --chown=node:node --from=builder /app/public ./public
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/package.json ./
USER node
CMD ["npm", "run", "start"]
