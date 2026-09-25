# Stage 1: Build the frontend app
FROM node:22-bookworm-slim AS builder

WORKDIR /usr/src/medplum

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json turbo.json tsconfig.json api-extractor.json tsdoc.json aliases.mjs ./
COPY packages/ ./packages/

ENV MEDPLUM_BASE_URL="__MEDPLUM_BASE_URL__" \
    MEDPLUM_CLIENT_ID="__MEDPLUM_CLIENT_ID__" \
    MEDPLUM_REGISTER_ENABLED="__MEDPLUM_REGISTER_ENABLED__" \
    MEDPLUM_AWS_TEXTRACT_ENABLED="__MEDPLUM_AWS_TEXTRACT_ENABLED__" \
    GOOGLE_CLIENT_ID="__GOOGLE_CLIENT_ID__" \
    RECAPTCHA_SITE_KEY="__RECAPTCHA_SITE_KEY__"

RUN npm ci --include=dev && \
    npx turbo run build --filter=@medplum/app...

# Stage 2: Serve via Nginx
FROM nginxinc/nginx-unprivileged:alpine
USER root

# Create Nginx configuration for SPA routing on port 3000
RUN printf 'server {\n\
    listen 3000;\n\
    server_name localhost;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    gzip on;\n\
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location /assets/ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, no-transform";\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

# Copy built assets from builder
COPY --from=builder /usr/src/medplum/packages/app/dist /usr/share/nginx/html
COPY packages/app/docker-entrypoint.sh /docker-entrypoint.sh

RUN chown -R 101:101 /usr/share/nginx/html && \
    chown 101:101 /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

EXPOSE 3000
USER 101

ENTRYPOINT ["/docker-entrypoint.sh"]
