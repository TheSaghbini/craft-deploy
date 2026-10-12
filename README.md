# craft-deploy

Imagens nginx que publicam a versão web dos apps da [Storytold](https://github.com/storytold). O Dockerfile da raiz baixa o zip web e o CLI Linux do release correspondente. O editor fica na porta 8080. O MCP do CLI, que só fala por stdin/stdout, aparece em `/mcp` no mesmo domínio. A variável `SUPERGATEWAY_API_KEY` é obrigatória; o cliente envia `Authorization: Bearer` ou `X-API-Key`.

O código dos apps é da Storytold, sob MIT e Apache-2.0. Este repositório só empacota esses zips.

| App | Repositório | Release |
| --- | --- | --- |
| PhotoCraft | https://github.com/storytold/photocraft | v0.7.0 |
| LightCraft | https://github.com/storytold/lightcraft | v0.6.0 |
| FilmCraft | https://github.com/storytold/filmcraft | v0.6.0 |
| EffectCraft | https://github.com/storytold/effectcraft | v0.8.0 |
| VectorCraft | https://github.com/storytold/vectorcraft | v0.10.0 |
| DesignCraft | https://github.com/storytold/designcraft | v0.6.0 |
| PdfCraft | https://github.com/storytold/pdfcraft | v0.7.1 |

Licenças: [MIT](https://github.com/storytold/photocraft/blob/main/LICENSE-MIT) e [Apache-2.0](https://github.com/storytold/photocraft/blob/main/LICENSE-APACHE).
