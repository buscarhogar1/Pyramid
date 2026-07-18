import { mkdir, readFile, writeFile } from "node:fs/promises";

const html = await readFile("index.html", "utf8");
const hostingConfig = await readFile(".openai/hosting.json", "utf8");

await mkdir("dist/server", { recursive: true });
await mkdir("dist/.openai", { recursive: true });

await writeFile("dist/.openai/hosting.json", hostingConfig);
await writeFile(
  "dist/server/index.js",
  `const html = ${JSON.stringify(html)};

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/" || url.pathname === "/privacy" || url.pathname === "/privacy-policy") {
      return new Response(html, {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "public, max-age=3600"
        }
      });
    }

    return new Response("Not found", {
      status: 404,
      headers: { "content-type": "text/plain; charset=utf-8" }
    });
  }
};
`
);
