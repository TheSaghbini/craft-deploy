#!/bin/sh
# nginx stays on 8080 for the editor and /healthz. The CLI speaks MCP on
# stdin/stdout, so supergateway exposes it on the loopback and nginx proxies
# /mcp. The API key is required: an empty key would publish the editor's
# command API with no authentication.
set -eu

if [ -z "${SUPERGATEWAY_API_KEY:-}" ]; then
  echo "SUPERGATEWAY_API_KEY is required" >&2
  exit 1
fi

mkdir -p /var/workspace \
  /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp
chown -R nginx:nginx /var/workspace \
  /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

nginx
exec runuser -u nginx -- env \
  HOME=/tmp \
  SUPERGATEWAY_API_KEY="$SUPERGATEWAY_API_KEY" \
  supergateway \
  --stdio "$(cat /etc/craft-mcp.command)" \
  --outputTransport streamableHttp \
  --stateful \
  --port 8081 \
  --host 127.0.0.1 \
  --streamableHttpPath /mcp \
  --healthEndpoint /gateway-health \
  --logLevel info
