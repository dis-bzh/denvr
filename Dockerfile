FROM node:lts-alpine as build
RUN apk update && apk upgrade
WORKDIR /app
COPY package*.json ./
RUN npm install -g npm
RUN npm install
COPY . ./
RUN npm run build

FROM nginx:stable-alpine-slim
RUN apk update && apk upgrade
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
