FROM node:11-alpine
WORKDIR /app

COPY package.json /app
RUN npm install

COPY . /app

CMD node app.js

EXPOSE 8081