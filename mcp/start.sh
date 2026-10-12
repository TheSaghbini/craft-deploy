#!/bin/sh
set -eu
exec node /usr/local/lib/node_modules/supergateway/dist/index.js --config /etc/craft/servers.json
