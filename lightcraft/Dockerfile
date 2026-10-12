# syntax=docker/dockerfile:1
ARG NGINX_VERSION=1.28-alpine
FROM nginx:${NGINX_VERSION}

ARG APP=lightcraft
ARG VERSION=0.6.0

USER root
RUN set -eu; \
    apk add --no-cache curl unzip; \
    zip="${APP}-web-${VERSION}.zip"; \
    url="https://github.com/storytold/${APP}/releases/download/v${VERSION}/${zip}"; \
    curl -fsSL --retry 3 -A Photocraft-dev -o /tmp/web.zip "$url"; \
    unzip -q /tmp/web.zip -d /tmp/web; \
    find /usr/share/nginx/html -mindepth 1 -delete; \
    cp -a "/tmp/web/${APP}-web-${VERSION}/." /usr/share/nginx/html/; \
    rm -rf /tmp/web /tmp/web.zip; \
    apk del curl unzip

COPY nginx/nginx.conf /etc/nginx/nginx.conf

USER nginx
EXPOSE 8080
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
