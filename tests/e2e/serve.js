// Minimal static file server for the built Flutter web app (SPA-aware).
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = process.argv[2];
const PORT = parseInt(process.argv[3] || '5000', 10);

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.map': 'application/json',
  '.txt': 'text/plain; charset=utf-8',
  '.webmanifest': 'application/manifest+json',
};

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/index.html';
  let filePath = path.join(ROOT, urlPath);
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403); res.end('forbidden'); return;
  }
  fs.stat(filePath, (err, stat) => {
    if (err || stat.isDirectory()) {
      // SPA fallback: unknown paths -> index.html (Flutter web uses hash routing
      // by default, but be tolerant).
      filePath = path.join(ROOT, 'index.html');
    }
    fs.readFile(filePath, (err2, data) => {
      if (err2) { res.writeHead(404); res.end('not found'); return; }
      const ext = path.extname(filePath).toLowerCase();
      const headers = { 'Content-Type': MIME[ext] || 'application/octet-stream' };
      // Never cache: E2E reloads must see fresh assets.
      headers['Cache-Control'] = 'no-store';
      if (ext === '.wasm') headers['Content-Length'] = data.length;
      res.writeHead(200, headers);
      res.end(data);
    });
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log('serving ' + ROOT + ' on http://127.0.0.1:' + PORT);
});
