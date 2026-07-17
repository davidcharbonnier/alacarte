# syntax=docker/dockerfile:1

# Dev stage: Vite dev server with HMR (docker-compose only).
# Production deploys to a static host (Netlify, etc.) — no Docker image needed.
FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY . .

EXPOSE 3000
CMD ["npm", "run", "dev"]
