// Local preview of build/web with the same headers Netlify will send
// (parsed from web/_headers). Usage: node tool/serve.mjs [port]
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { join, extname, normalize, resolve } from 'node:path';

const root = resolve('build/web');
const port = Number(process.argv[2] || 8080);

// Minimal _headers parser: "path" lines followed by indented "Name: value".
const rules = [];
let cur = null;
for (const line of readFileSync(join(root, '_headers'), 'utf8').split(/\r?\n/)) {
  if (!line.trim()) continue;
  if (!/^\s/.test(line)) { cur = { path: line.trim(), headers: {} }; rules.push(cur); continue; }
  const i = line.indexOf(':');
  if (cur && i > 0) cur.headers[line.slice(0, i).trim()] = line.slice(i + 1).trim();
}
const match = (p, pat) => pat.endsWith('*') ? p.startsWith(pat.slice(0, -1)) : p === pat;

const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.png': 'image/png', '.wasm': 'application/wasm',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.txt': 'text/plain', '.bin': 'application/octet-stream',
  '.frag': 'text/plain', '.symbols': 'text/plain',
};

createServer((req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let file = normalize(join(root, p));
  if (!file.startsWith(root)) { res.writeHead(403).end(); return; }
  if (existsSync(file) && statSync(file).isDirectory()) file = join(file, 'index.html');
  const status = existsSync(file) ? 200 : 404;
  if (status === 404) file = join(root, 'index.html');
  for (const r of rules) if (match(p, r.path)) for (const [k, v] of Object.entries(r.headers)) {
    if (k === 'Strict-Transport-Security' || (k === 'Content-Security-Policy')) {
      res.setHeader(k, k === 'Content-Security-Policy' ? v.replace('; upgrade-insecure-requests', '') : v);
    } else res.setHeader(k, v);
  }
  res.setHeader('Content-Type', types[extname(file)] || 'application/octet-stream');
  res.writeHead(status);
  res.end(readFileSync(file));
}).listen(port, () => console.log(`Basil preview on http://localhost:${port}`));
