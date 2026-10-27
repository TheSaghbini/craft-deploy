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
    && npm install -g supergateway@4.2.0-rc.1 \
    && test -x /usr/local/bin/supergateway \
    && test -f /usr/local/lib/node_modules/supergateway/dist/index.js \
    && rm -rf /root/.npm \
    && apt-get purge -y xz-utils \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# These files change when GitHub publishes a release, so the download below
# follows the latest tag instead of staying on a pinned version.
ADD https://api.github.com/repos/storytold/photocraft/releases/latest /tmp/rel/photocraft.json
ADD https://api.github.com/repos/storytold/lightcraft/releases/latest /tmp/rel/lightcraft.json
ADD https://api.github.com/repos/storytold/filmcraft/releases/latest /tmp/rel/filmcraft.json
ADD https://api.github.com/repos/storytold/effectcraft/releases/latest /tmp/rel/effectcraft.json
ADD https://api.github.com/repos/storytold/vectorcraft/releases/latest /tmp/rel/vectorcraft.json
ADD https://api.github.com/repos/storytold/designcraft/releases/latest /tmp/rel/designcraft.json
ADD https://api.github.com/repos/storytold/pdfcraft/releases/latest /tmp/rel/pdfcraft.json
ADD https://api.github.com/repos/storytold/wordcraft/releases/latest /tmp/rel/wordcraft.json
ADD https://api.github.com/repos/storytold/gridcraft/releases/latest /tmp/rel/gridcraft.json
ADD https://api.github.com/repos/storytold/deckcraft/releases/latest /tmp/rel/deckcraft.json
ADD https://api.github.com/repos/storytold/cadcraft/releases/latest /tmp/rel/cadcraft.json
ADD https://api.github.com/repos/storytold/soundcraft/releases/latest /tmp/rel/soundcraft.json
ADD https://api.github.com/repos/storytold/figcraft/releases/latest /tmp/rel/figcraft.json

ARG RAILWAY_SERVICE_NAME

USER root
RUN set -eu; \
    name=$(printf '%s' "${RAILWAY_SERVICE_NAME:-}" | tr '[:upper:]' '[:lower:]'); \
    case "$name" in \
      photocraft) mcp="photocraft-cli mcp --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      lightcraft) mcp="lightcraft-cli mcp" ;; \
      filmcraft) mcp="filmcraft-cli mcp --demo" ;; \
      effectcraft) mcp="effectcraft-cli mcp" ;; \
      vectorcraft) mcp="vectorcraft-cli mcp --headless --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      designcraft) mcp="designcraft-cli mcp" ;; \
      pdfcraft) mcp="pdfcraft-cli mcp --root /var/workspace" ;; \
      wordcraft) mcp="wordcraft-cli mcp --author AgenticOS --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      gridcraft) mcp="gridcraft-cli mcp" ;; \
      deckcraft) mcp="deckcraft-cli mcp --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      cadcraft) mcp="cadcraft-cli mcp" ;; \
      soundcraft) mcp="soundcraft-cli mcp --demo --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      figcraft) mcp="figcraft-cli mcp --automation-read-root /var/workspace --automation-write-root /var/workspace" ;; \
      *) echo "unknown service: ${RAILWAY_SERVICE_NAME:-<empty>}" >&2; exit 1 ;; \
    esac; \
    tag=$(grep -o '"tag_name": *"[^"]*"' "/tmp/rel/${name}.json" | head -n 1 | sed 's/.*"\(v[^"]*\)".*/\1/'); \
    version=${tag#v}; \
    test -n "$version"; \
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
    found=$(find /tmp/cli -type f -path "*/bin/${name}-cli" | head -n 1); \
    test -n "$found"; \
    install -m 755 "$found" "/usr/local/bin/${name}-cli"; \
    "/usr/local/bin/${name}-cli" --version; \
    printf '%s' "$mcp" > /etc/craft-mcp.command; \
    rm -rf /tmp/web /tmp/web.zip /tmp/cli /tmp/cli.tar.gz

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/craft-http.conf /etc/nginx/craft-http.conf
COPY nginx/craft-server.conf /etc/nginx/craft-server.conf
COPY nginx/start.sh /usr/local/bin/start-craft
RUN chmod 755 /usr/local/bin/start-craft

EXPOSE 8080
ENTRYPOINT []
CMD ["/usr/local/bin/start-craft"]
