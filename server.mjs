import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const distIndex = path.join(here, 'dist', 'index.html');
const rootIndex = path.join(here, 'index.html');
// Serve dist/ when it exists (build output), else project root.
const root = fs.existsSync(distIndex) ? path.join(here, 'dist') : here;

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
};

const server = http.createServer((req, res) => {
  let p = '/index.html';
  try {
    p = decodeURIComponent(String(req.url || '/').split('?')[0]);
  } catch { p = '/index.html'; }
  if (p === '/') p = '/index.html';
  const file = path.join(root, path.normalize(p).replace(/^[/\\]+/, ''));
  if (!file.startsWith(root)) {
    res.writeHead(403);
    res.end('forbidden');
    return;
  }
  fs.readFile(file, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

const port = Number(process.env.PORT || 3000);
server.listen(port, '0.0.0.0', () => {
  console.log(`PlayGround Dodger serving ${root} on http://127.0.0.1:${port}/`);
});
