# Install node-modules
FROM node:bookworm-slim AS deps
WORKDIR /usr/app/
RUN apt-get update && apt-get install -y build-essential python3
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
# Create build directory
FROM node:bookworm-slim AS builder
RUN apt-get update && apt-get install -y build-essential python3
WORKDIR /usr/app
COPY --from=deps /usr/app/node_modules ./node_modules
COPY /. .
RUN npm run build
# Create node-modules for production version (only dev dependencies)
FROM node:bookworm-slim AS prod-deps
RUN apt-get update && apt-get install -y build-essential python3
WORKDIR /usr/app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
# Create final image
FROM node:bookworm-slim AS production
WORKDIR /usr/app
COPY --from=prod-deps /usr/app/node_modules ./node_modules
COPY --from=builder /usr/app/build ./build
ENV NODE_ENV=production
CMD ["node","build/app.js"]
EXPOSE 3000
