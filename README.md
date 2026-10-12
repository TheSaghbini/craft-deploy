# craft-deploy

Railway images for the seven [Storytold](https://github.com/storytold) creative apps, plus one [supergateway](https://github.com/supercorp-ai/supergateway) service that exposes all of them as a single MCP server.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/craft-web-suite-mcp?referralCode=Kqm1It&utm_medium=integration&utm_source=template&utm_campaign=generic)

The apps are open source (MIT or Apache-2.0). This repository does not build them. Each image downloads the latest GitHub Release and serves it.

| App | What it is | Repository |
| --- | --- | --- |
| PhotoCraft | Image editor. Layers, masks, type, vectors, and PSD files. | https://github.com/storytold/photocraft |
| LightCraft | Photo library and raw developing. The catalog stays local to the session. | https://github.com/storytold/lightcraft |
| FilmCraft | Video editing, color, and sound. | https://github.com/storytold/filmcraft |
| EffectCraft | Motion graphics and visual effects. | https://github.com/storytold/effectcraft |
| VectorCraft | Vector illustration. | https://github.com/storytold/vectorcraft |
| DesignCraft | Page layout and publishing. | https://github.com/storytold/designcraft |
| PdfCraft | PDF workbench: read, organize, combine, split, and secure. | https://github.com/storytold/pdfcraft |

## What a deploy runs

The root `Dockerfile` is what Railway builds. It picks the app from `RAILWAY_SERVICE_NAME` and reads that app's latest release from the GitHub API while the image builds. A new Storytold release is picked up on the next deploy of that service.

Each app container does three things:

- nginx on port 8080 serves the web build (the editor in the browser). `GET /healthz` returns `ok`.
- The Linux CLI from the same release is installed at `/usr/local/bin/<app>-cli`.
- [supergateway](https://github.com/supercorp-ai/supergateway) `4.2.0-rc.1` runs that CLI, which only speaks MCP on stdin/stdout, and nginx proxies it at `POST /mcp` (Streamable HTTP, stateful). The image installs that npm release because `4.1.0` has no config file and no API key.

`SUPERGATEWAY_API_KEY` is required. Clients send `Authorization: Bearer <key>` or `X-API-Key: <key>`. The CLI can only read and write `/var/workspace` where the app supports that flag. The directory is empty on every new container, so documents do not survive a restart.

Web assets and the CLI always come from the same release tag. JavaScript and WebAssembly are served with `Cache-Control: no-cache`, because some apps do not hash those filenames.

## One MCP for every app

The `mcp/` directory is a separate Railway service. It does not download the apps. It runs supergateway with `mcp/servers.json`, which connects to each app's private `/mcp` and publishes them together at:

```text
https://<mcp-service>/suite/mcp
```

Tool names are prefixed (`photocraft_doc_new`, `lightcraft_query_photos`, `pdfcraft_text_extract`, and so on). Without the prefix, apps that all expose `command_run` would hide one another. The same `SUPERGATEWAY_API_KEY` locks this endpoint. The gateway sends that key to each app.

Set these variables on the MCP service. `RAILWAY_PRIVATE_DOMAIN` is the private hostname of that app's service, and nginx listens on 8080:

```text
PHOTOCRAFT_MCP=http://${{PhotoCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
LIGHTCRAFT_MCP=http://${{LightCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
FILMCRAFT_MCP=http://${{FilmCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
EFFECTCRAFT_MCP=http://${{EffectCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
VECTORCRAFT_MCP=http://${{VectorCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
DESIGNCRAFT_MCP=http://${{DesignCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
PDFCRAFT_MCP=http://${{PdfCraft.RAILWAY_PRIVATE_DOMAIN}}:8080/mcp
SUPERGATEWAY_API_KEY=<secret>
```

Point the MCP service at this repository with root directory `mcp`. The root `Dockerfile` only builds a named app, so a service whose root directory is the repository root will not start the gateway.

A combined session starts one session on each app. A document created through `photocraft_doc_new` lives in the PhotoCraft container, not in the gateway.

There are several hundred tools on `/suite/mcp` (LightCraft alone exposes a few hundred). A client that should drive one app can still call that app's own `https://<app>/mcp`.

## Layout

```text
Dockerfile          one image per app, selected by RAILWAY_SERVICE_NAME
nginx/nginx.conf    editor, /healthz, and the /mcp proxy
nginx/start.sh      nginx plus supergateway
mcp/Dockerfile      the combined MCP service
mcp/servers.json    the seven upstream MCP endpoints
icons/              marketplace card art
```

The Dockerfiles under each app directory are the earlier per-folder recipes. Railway template deploys do not keep a Dockerfile path, so production builds use the root file.

## License

Copyright (c) 2026 ArtCraft Team and each app's contributors. Licensed under the MIT License or the Apache License, Version 2.0, at your option ([MIT](https://github.com/storytold/photocraft/blob/main/LICENSE-MIT), [Apache-2.0](https://github.com/storytold/photocraft/blob/main/LICENSE-APACHE)).

Storytold is the GitHub organization. The ArtCraft wordmark and logos are not part of this repository and are not used here.
