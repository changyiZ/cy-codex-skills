#!/usr/bin/env node
import { readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { mkdir } from "node:fs/promises";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { transform } = require(resolve(process.cwd(), "tools/wechat/node_modules/esbuild"));

const [, , inputPath, outputPath] = process.argv;

if (!inputPath || !outputPath) {
  console.error("usage: transpile_js.mjs <input-js> <output-js>");
  process.exit(1);
}

const source = await readFile(inputPath, "utf8");
const result = await transform(source, {
  loader: "js",
  target: "es2018",
  charset: "utf8",
  legalComments: "none",
  supported: {
    arrow: false,
  },
});

await mkdir(dirname(resolve(outputPath)), { recursive: true });
await writeFile(outputPath, result.code, "utf8");
