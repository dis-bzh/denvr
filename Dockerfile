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

FROM nginx:stable-alpine-slim
RUN apk update && apk upgrade
COPY --from=builder --chown=nginx:nginx /app/out /usr/share/nginx/html
WORKDIR /app
RUN chown -R nginx:nginx /var/cache/nginx && \
        chown -R nginx:nginx /var/log/nginx && \
        chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
chown -R nginx:nginx /var/run/nginx.pid
USER nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
