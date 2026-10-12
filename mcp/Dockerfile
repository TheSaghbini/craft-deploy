# syntax=docker/dockerfile:1
# One MCP endpoint for the seven Storytold apps.
# 4.1.0 has no --config. 4.2.0-rc.1 serves several servers from one file.
FROM node:22-bookworm-slim

RUN npm install -g supergateway@4.2.0-rc.1 \
    && test -f /usr/local/lib/node_modules/supergateway/dist/index.js \
    && rm -rf /root/.npm

COPY servers.json /etc/craft/servers.json
COPY start.sh /usr/local/bin/start-mcp
RUN chmod 755 /usr/local/bin/start-mcp

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/start-mcp"]
