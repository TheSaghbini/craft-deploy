# syntax=docker/dockerfile:1
# Template deploys do not keep a per-service Dockerfile path. Railway still
# passes the service name, so this root file builds the matching app.
ARG NGINX_VERSION=1.28-alpine
FROM nginx:${NGINX_VERSION}

ARG RAILWAY_SERVICE_NAME

USER root
RUN set -eu; \
    name=$(printf '%s' "${RAILWAY_SERVICE_NAME:-}" | tr '[:upper:]' '[:lower:]'); \
    case "$name" in \
      photocraft) version=0.7.0 ;; \
      lightcraft) version=0.6.0 ;; \
      filmcraft) version=0.6.0 ;; \
      effectcraft) version=0.8.0 ;; \
      vectorcraft) version=0.10.0 ;; \
      designcraft) version=0.6.0 ;; \
      pdfcraft) version=0.7.1 ;; \
      *) echo "unknown service: ${RAILWAY_SERVICE_NAME:-<empty>}" >&2; exit 1 ;; \
    esac; \
    apk add --no-cache curl unzip; \
    zip="${name}-web-${version}.zip"; \
    url="https://github.com/storytold/${name}/releases/download/v${version}/${zip}"; \
    echo "building ${name} ${version}"; \
    curl -fsSL --retry 3 -A Photocraft-dev -o /tmp/web.zip "$url"; \
    unzip -q /tmp/web.zip -d /tmp/web; \
    find /usr/share/nginx/html -mindepth 1 -delete; \
    cp -a "/tmp/web/${name}-web-${version}/." /usr/share/nginx/html/; \
    rm -rf /tmp/web /tmp/web.zip; \
    apk del curl unzip

COPY nginx/nginx.conf /etc/nginx/nginx.conf

USER nginx
EXPOSE 8080
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
