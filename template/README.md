# Deploy and Host Craft Web Suite + MCP with Railway

Craft Web Suite hosts seven Storytold apps in the browser and joins their command-line MCP servers into one endpoint. PhotoCraft, LightCraft, FilmCraft, EffectCraft, VectorCraft, DesignCraft, and PdfCraft each run as their own service. A supergateway service, MCP, exposes every app at a single Streamable HTTP URL.

## About Hosting Craft Web Suite + MCP

Railway builds the images from [feliperosenek/craft-deploy](https://github.com/feliperosenek/craft-deploy). The root Dockerfile downloads the latest Storytold web release and the matching Linux CLI, then serves the editor on port 8080. [supergateway](https://github.com/supercorp-ai/supergateway) turns that CLI, which only speaks MCP on stdin/stdout, into `POST /mcp` on the same domain.

The MCP service uses the `mcp/` directory of the same repository. It does not run the editors. It connects to each app over the Railway private network and publishes one stateful MCP server at `/suite/mcp`. Tool names carry the app as a prefix, so `photocraft_doc_new` and `pdfcraft_text_extract` stay distinct.

`SUPERGATEWAY_API_KEY` is required. Send it as `Authorization: Bearer` or `X-API-Key`. Documents stay in the app container that handled the call. Nothing is stored on a volume, and a new deploy starts from an empty workspace.

A generated domain provides HTTPS, which the browser editors need for WebGPU. `GET /healthz` is the health check.

## Common Use Cases

- Open the seven editors, each on its own URL.
- Drive every app from one MCP client connected to `/suite/mcp`.
- Let an agent edit an image, a photo library, a timeline, a composition, a vector file, a layout, or a PDF through the same session.
- Pick up a new Storytold release by redeploying the service. The image resolves the latest GitHub Release at build time.

## Dependencies for Craft Web Suite + MCP Hosting

- nginx 1.28, listening on port 8080, for each app.
- supergateway 4.2.0-rc.1, in each app and in the MCP service. The 4.1.0 npm release does not include the multi-server config or API keys.
- The public repository feliperosenek/craft-deploy.
- The latest GitHub Release of each Storytold app (web zip and Linux CLI).

### Deployment Dependencies

- [feliperosenek/craft-deploy](https://github.com/feliperosenek/craft-deploy)
- [supercorp-ai/supergateway](https://github.com/supercorp-ai/supergateway)
- [storytold/photocraft](https://github.com/storytold/photocraft)
- [storytold/lightcraft](https://github.com/storytold/lightcraft)
- [storytold/filmcraft](https://github.com/storytold/filmcraft)
- [storytold/effectcraft](https://github.com/storytold/effectcraft)
- [storytold/vectorcraft](https://github.com/storytold/vectorcraft)
- [storytold/designcraft](https://github.com/storytold/designcraft)
- [storytold/pdfcraft](https://github.com/storytold/pdfcraft)

Copyright (c) 2026 ArtCraft Team and each app's contributors. Licensed under the MIT License or the Apache License, Version 2.0, at your option ([MIT](https://github.com/storytold/photocraft/blob/main/LICENSE-MIT), [Apache-2.0](https://github.com/storytold/photocraft/blob/main/LICENSE-APACHE)).

### Why Deploy Craft Web Suite + MCP on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Craft Web Suite + MCP on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
