import { cp, mkdir, readFile, writeFile } from "node:fs/promises";

const html = await readFile("index.html", "utf8");
const hostingConfig = await readFile(".openai/hosting.json", "utf8");
const roomApi = await readFile("server/room-api.js", "utf8");

await mkdir("dist/server", { recursive: true });
await mkdir("dist/.openai", { recursive: true });

await writeFile("dist/.openai/hosting.json", hostingConfig);
await cp("drizzle", "dist/.openai/drizzle", { recursive: true });
await writeFile(
  "dist/server/index.js",
  `const html = ${JSON.stringify(html)};

${roomApi}
`
);
