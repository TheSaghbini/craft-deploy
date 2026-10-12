# syntax=docker/dockerfile:1
# Template deploys do not keep a per-service Dockerfile path. Railway still
# passes the service name, so this root file builds the matching app.
# Debian, not Alpine: the official CLI binaries are glibc.
FROM nginx:1.28

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl xz-utils unzip tar \
    && curl -fsSL -o /tmp/node.tar.xz https://nodejs.org/dist/v22.23.3/node-v22.23.3-linux-x64.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && npm install -g supergateway@4.1.0 \
    && rm -rf /root/.npm \
    && apt-get purge -y xz-utils \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ARG RAILWAY_SERVICE_NAME

USER root
RUN set -eu; \
    name=$(printf '%s' "${RAILWAY_SERVICE_NAME:-}" | tr '[:upper:]' '[:lower:]'); \
    case "$name" in \
      photocraft) version=0.7.0; mcp="photocraft-cli mcp --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      lightcraft) version=0.6.0; mcp="lightcraft-cli mcp" ;; \
      filmcraft) version=0.6.0; mcp="filmcraft-cli mcp --demo" ;; \
      effectcraft) version=0.8.0; mcp="effectcraft-cli mcp" ;; \
      vectorcraft) version=0.10.0; mcp="vectorcraft-cli mcp --headless --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      designcraft) version=0.6.0; mcp="designcraft-cli mcp" ;; \
      pdfcraft) version=0.7.1; mcp="pdfcraft-cli mcp --root /var/workspace" ;; \
      *) echo "unknown service: ${RAILWAY_SERVICE_NAME:-<empty>}" >&2; exit 1 ;; \
    esac; \
    echo "building ${name} ${version}"; \
    zip="${name}-web-${version}.zip"; \
    web="https://github.com/storytold/${name}/releases/download/v${version}/${zip}"; \
    curl -fsSL --retry 3 -A Photocraft-dev -o /tmp/web.zip "$web"; \
    unzip -q /tmp/web.zip -d /tmp/web; \
    find /usr/share/nginx/html -mindepth 1 -delete; \
    cp -a "/tmp/web/${name}-web-${version}/." /usr/share/nginx/html/; \
    chmod -R a+rX /usr/share/nginx/html; \
    tarball="${name}-${version}-linux-x86_64.tar.gz"; \
    cli="https://github.com/storytold/${name}/releases/download/v${version}/${tarball}"; \
    mkdir -p /tmp/cli; \
    curl -fsSL --retry 3 -A Photocraft-dev -o /tmp/cli.tar.gz "$cli"; \
    tar -xzf /tmp/cli.tar.gz -C /tmp/cli; \
    found=$(find /tmp/cli -type f -name "${name}-cli" | head -n 1); \
    test -n "$found"; \
    install -m 755 "$found" "/usr/local/bin/${name}-cli"; \
    "/usr/local/bin/${name}-cli" --version; \
    printf '%s' "$mcp" > /etc/craft-mcp.command; \
    rm -rf /tmp/web /tmp/web.zip /tmp/cli /tmp/cli.tar.gz

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/start.sh /usr/local/bin/start-craft
RUN chmod 755 /usr/local/bin/start-craft

EXPOSE 8080
ENTRYPOINT []
CMD ["/usr/local/bin/start-craft"]
