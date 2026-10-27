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

# The key is embedded in the nginx map. Reject characters that would break
# the quoted value or be read as an nginx variable.
case "$SUPERGATEWAY_API_KEY" in
  *[!A-Za-z0-9_./+=-]*)
    echo "SUPERGATEWAY_API_KEY cannot be used for file downloads" >&2
    exit 1
    ;;
esac

cat > /etc/nginx/craft-http.conf <<EOF
map \$http_authorization \$office_file_ok {
    default 0;
    "Bearer ${SUPERGATEWAY_API_KEY}" 1;
}
EOF

cat > /etc/nginx/craft-server.conf <<'EOF'
location ~* ^/files/([A-Za-z0-9][A-Za-z0-9._-]*\.(docx|xlsx|pptx))$ {
    limit_except GET HEAD {
        deny all;
    }
    if ($office_file_ok = 0) {
        return 401;
    }
    rewrite ^ /_office_file/$1 last;
}

location ^~ /_office_file/ {
    internal;
    alias /var/workspace/;
    autoindex off;
    default_type application/octet-stream;
    add_header X-Content-Type-Options nosniff always;
    add_header Cache-Control "private, no-store" always;
}
EOF
chmod 600 /etc/nginx/craft-http.conf /etc/nginx/craft-server.conf

mkdir -p /var/workspace \
  /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp
chown -R nginx:nginx /var/workspace \
  /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp

if ! nginx -t >/tmp/nginx-test.txt 2>&1; then
  echo "nginx config test failed" >&2
  while IFS= read -r line; do
    case "$line" in
      *Bearer*) ;;
      *) printf '%s\n' "$line" >&2 ;;
    esac
  done < /tmp/nginx-test.txt
  exit 1
fi
rm -f /tmp/nginx-test.txt

nginx

probe=""
for _ in 1 2 3 4 5; do
  probe=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/files/probe.docx || true)
  if [ "$probe" = "401" ]; then
    break
  fi
  sleep 1
done
if [ "$probe" != "401" ]; then
  echo "office file route check returned ${probe:-none}" >&2
  exit 1
fi

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
  --apiKey "$SUPERGATEWAY_API_KEY" \
  --logLevel info
