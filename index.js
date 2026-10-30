const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const ROOT_DIR = process.cwd();
const SPEC_EXTS = ['.vg', '.vl', '.vg.json', '.vl.json', '.json'];
const WATCH_EXTS = ['.vg', '.vl', '.json', '.csv', '.tsv'];
const IGNORE_DIRS = new Set(['node_modules', '.git', '.cache', 'dist', 'build', '.vscode', '.idea']);
const IGNORE_FILES = new Set(['package.json', 'package-lock.json', 'tsconfig.json']);

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.vg': 'application/json; charset=utf-8',
  '.vl': 'application/json; charset=utf-8',
  '.csv': 'text/csv; charset=utf-8',
  '.tsv': 'text/tab-separated-values; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.txt': 'text/plain; charset=utf-8',
};

let clients = [];

function broadcast(event) {
  const msg = `data: ${JSON.stringify(event)}\n\n`;
  clients.forEach((res) => res.write(msg));
}

// Strip spec extension (.vg.json, .vl.json, .vg, .vl, .json)
function stripSpecExtension(filePath) {
  const lower = filePath.toLowerCase();
  for (const ext of ['.vg.json', '.vl.json', '.json', '.vg', '.vl']) {
    if (lower.endsWith(ext)) {
      return filePath.slice(0, -ext.length);
    }
  }
  return filePath;
}

// Convert "me/time/distance.vg" into "me / time / distance"
function formatDisplayPath(relPath) {
  const withoutExt = stripSpecExtension(relPath);
  return withoutExt.split('/').join(' / ');
}

// Check if a parsed JSON object looks like a Vega / Vega-Lite spec rather than raw tabular data
function isLikelyVegaSpec(parsed, filename) {
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return false;
  const lower = filename.toLowerCase();
  if (lower.endsWith('.vg') || lower.endsWith('.vl') || lower.endsWith('.vg.json') || lower.endsWith('.vl.json')) {
    return true;
  }
  const vegaKeys = [
    '$schema', 'marks', 'mark', 'encoding', 'layer',
    'hconcat', 'vconcat', 'concat', 'facet', 'repeat', 'signals', 'scales'
  ];
  return vegaKeys.some((k) => k in parsed);
}

// Detect vega vs vega-lite mode
function detectMode(spec, filename) {
  if (spec && typeof spec.$schema === 'string') {
    if (spec.$schema.includes('vega-lite')) return 'vega-lite';
    if (spec.$schema.includes('vega')) return 'vega';
  }
  const lower = filename.toLowerCase();
  if (lower.endsWith('.vl') || lower.endsWith('.vl.json')) return 'vega-lite';
  if (spec && ('mark' in spec || 'encoding' in spec || 'layer' in spec || 'facet' in spec || 'repeat' in spec)) {
    return 'vega-lite';
  }
  return 'vega';
}

// Recursively find all files in directory
function walkDir(dir, fileList = []) {
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name.startsWith('.') || entry.name.endsWith('~') || entry.name.endsWith('.swp')) continue;
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (IGNORE_DIRS.has(entry.name)) continue;
        walkDir(fullPath, fileList);
      } else if (entry.isFile()) {
        if (IGNORE_FILES.has(entry.name)) continue;
        fileList.push(fullPath);
      }
    }
  } catch (_) {}
  return fileList;
}

// Read, parse, and sort specs across root and all subdirectories
function getSpecs() {
  const allFiles = walkDir(ROOT_DIR);
  const specs = [];

  for (const fullPath of allFiles) {
    const relPath = path.relative(ROOT_DIR, fullPath).split(path.sep).join('/');
    const lowerRel = relPath.toLowerCase();

    const matches = SPEC_EXTS.some((ext) => lowerRel.endsWith(ext));
    if (!matches) continue;

    const raw = fs.readFileSync(fullPath, 'utf8');
    const filename = path.basename(fullPath);
    const displayName = formatDisplayPath(relPath);

    try {
      const parsed = JSON.parse(raw);
      if (!isLikelyVegaSpec(parsed, filename)) continue;
      specs.push({
        relPath,
        displayName,
        filename,
        mode: detectMode(parsed, filename),
        spec: parsed,
        error: null,
      });
    } catch (err) {
      specs.push({
        relPath,
        displayName,
        filename,
        mode: 'vega',
        spec: null,
        error: err.message,
      });
    }
  }

  // Sort by relative path naturally (e.g. 1, 2, 10 instead of 1, 10, 2)
  return specs.sort((a, b) => a.relPath.localeCompare(b.relPath, undefined, { numeric: true, sensitivity: 'base' }));
}

// Recursive directory watcher compatible with Linux/Android (Termux)
const watchedDirs = new Map();
let debounceTimeout = null;

function watchDirRecursive(dir) {
  if (watchedDirs.has(dir)) return;
  try {
    const watcher = fs.watch(dir, (eventType, filename) => {
      if (!filename) return;
      if (filename.startsWith('.') || filename.endsWith('~') || filename.endsWith('.swp') || filename.endsWith('.swo')) return;
      if (IGNORE_FILES.has(filename)) return;

      const fullPath = path.join(dir, filename);
      try {
        if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
          rescanWatchers();
        }
      } catch (_) {}

      const lower = filename.toLowerCase();
      const isMatch = WATCH_EXTS.some((ext) => lower.endsWith(ext));
      if (!isMatch) return;

      clearTimeout(debounceTimeout);
      debounceTimeout = setTimeout(() => {
        broadcast({ type: 'reload', filename: path.relative(ROOT_DIR, fullPath) });
      }, 120);
    });
    watchedDirs.set(dir, watcher);
  } catch (_) {}
}

function rescanWatchers() {
  const dirs = [ROOT_DIR];
  function collect(current) {
    try {
      const entries = fs.readdirSync(current, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isDirectory() && !entry.name.startsWith('.') && !IGNORE_DIRS.has(entry.name)) {
          const sub = path.join(current, entry.name);
          dirs.push(sub);
          collect(sub);
        }
      }
    } catch (_) {}
  }
  collect(ROOT_DIR);
  dirs.forEach(watchDirRecursive);
}

rescanWatchers();

const CLIENT_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=0.25, maximum-scale=10.0, user-scalable=yes">
  <title>Vega & Vega-Lite Live Dashboard</title>
  <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
  <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
  <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
  <style>
    :root {
      --bg: #121418;
      --card-bg: #1c1f26;
      --border: #2e3440;
      --text: #e5e9f0;
      --accent: #88c0d0;
      --error-bg: #3b2426;
      --error-text: #ff7b72;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace;
      background: var(--bg);
      color: var(--text);
      padding: 1rem;
      min-width: min-content;
    }
    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
      border-bottom: 1px solid var(--border);
      padding-bottom: 0.75rem;
      gap: 1rem;
      flex-wrap: wrap;
    }
    h1 { font-size: 1.25rem; font-weight: 600; color: var(--accent); }
    .controls { display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap; }
    button {
      background: var(--card-bg);
      color: var(--text);
      border: 1px solid var(--border);
      padding: 0.35rem 0.75rem;
      border-radius: 6px;
      cursor: pointer;
      font-family: inherit;
      font-size: 0.8rem;
    }
    button:hover { border-color: var(--accent); }
    #status { font-size: 0.85rem; opacity: 0.8; }

    .grid {
      display: flex;
      flex-wrap: wrap;
      gap: 1.5rem;
      align-items: stretch;
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem;
      display: flex;
      flex-direction: column;
      flex: 1 1 auto;
      width: max-content;
      min-width: min(100%, 460px);
    }
    .card-title {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 1rem;
      font-size: 0.95rem;
      font-weight: 600;
      margin-bottom: 0.75rem;
      color: var(--accent);
      border-bottom: 1px solid var(--border);
      padding-bottom: 0.4rem;
    }
    .badge {
      font-size: 0.75rem;
      opacity: 0.75;
      font-weight: normal;
      white-space: nowrap;
    }
    .chart-container {
      flex: 1;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 250px;
      width: 100%;
      min-width: max-content;
      padding: 1rem 1.25rem;
      border-radius: 6px;
      cursor: zoom-in;
    }
    .chart-container.light-bg,
    .dialog-viewport.light-bg {
      background: #ffffff;
      color: #111111;
    }
    .chart-container .vega-embed {
      padding-right: 36px !important;
    }
    .chart-container svg,
    .dialog-viewport svg {
      display: block;
      max-width: none !important;
      height: auto;
    }
    .error-box {
      background: var(--error-bg);
      color: var(--error-text);
      padding: 0.75rem;
      border-radius: 4px;
      font-family: monospace;
      font-size: 0.85rem;
      white-space: pre-wrap;
      width: 100%;
    }

    dialog#fullscreenDialog {
      width: 100vw;
      height: 100vh;
      max-width: 100vw;
      max-height: 100vh;
      margin: 0;
      padding: 0;
      border: none;
      background: var(--bg);
      color: var(--text);
      overflow: hidden;
    }
    dialog#fullscreenDialog::backdrop {
      background: rgba(0, 0, 0, 0.85);
    }
    .dialog-shell {
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
    }
    .dialog-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.65rem 1rem;
      background: var(--card-bg);
      border-bottom: 1px solid var(--border);
      gap: 1rem;
      flex-wrap: wrap;
      z-index: 10;
    }
    .dialog-title {
      font-weight: 600;
      color: var(--accent);
      font-size: 0.95rem;
    }
    .dialog-actions {
      display: flex;
      align-items: center;
      gap: 0.45rem;
      flex-wrap: wrap;
    }
    .zoom-label {
      font-size: 0.8rem;
      min-width: 3.5rem;
      text-align: center;
      opacity: 0.85;
    }
    .dialog-viewport {
      flex: 1;
      overflow: auto;
      display: flex;
      padding: 2rem;
      cursor: grab;
      touch-action: pan-x pan-y pinch-zoom;
    }
    .dialog-viewport.dragging {
      cursor: grabbing;
      user-select: none;
    }
    .dialog-canvas {
      margin: auto;
      display: inline-block;
    }
  </style>
</head>
<body>
  <header>
    <h1>Vega Live Dashboard</h1>
    <div class="controls">
      <button id="themeBtn">Chart Theme: Light</button>
      <span id="status">Connecting...</span>
    </div>
  </header>
  <main class="grid" id="charts"></main>

  <dialog id="fullscreenDialog">
    <div class="dialog-shell">
      <div class="dialog-bar">
        <span class="dialog-title" id="dialogTitle">Chart</span>
        <div class="dialog-actions">
          <button type="button" id="zoomOutBtn" title="Zoom Out">−</button>
          <span class="zoom-label" id="zoomLabel">100%</span>
          <button type="button" id="zoomInBtn" title="Zoom In">+</button>
          <button type="button" id="zoomFitBtn" title="Fit to Screen">Fit</button>
          <button type="button" id="zoomResetBtn" title="Actual Size (100%)">100%</button>
          <button type="button" id="closeDialogBtn" title="Close (Esc)">✕ Close</button>
        </div>
      </div>
      <div class="dialog-viewport light-bg" id="dialogViewport">
        <div class="dialog-canvas" id="dialogCanvas"></div>
      </div>
    </div>
  </dialog>

  <script>
    const statusEl = document.getElementById('status');
    const chartsEl = document.getElementById('charts');
    const themeBtn = document.getElementById('themeBtn');
    const dialog = document.getElementById('fullscreenDialog');
    const dialogTitle = document.getElementById('dialogTitle');
    const dialogViewport = document.getElementById('dialogViewport');
    const dialogCanvas = document.getElementById('dialogCanvas');
    const zoomLabel = document.getElementById('zoomLabel');

    const activeViews = new Map();
    let latestSpecs = new Map();
    let useDarkTheme = false;

    let currentModalKey = null;
    let baseSvgSize = { width: 0, height: 0 };
    let currentZoom = 1;

    // Resolves relative data URLs relative to the spec's folder with a fallback to the root
    function createCustomLoader(specRelPath, loadErrors) {
      const loader = vega.loader();
      const origHttp = loader.http.bind(loader);
      const lastSlash = specRelPath.lastIndexOf('/');
      const specDir = lastSlash !== -1 ? '/' + specRelPath.slice(0, lastSlash + 1) : '/';

      loader.http = async function(url, options) {
        const bust = (u) => (u.includes('?') ? u : \`\${u}?t=\${Date.now()}\`);
        let targetUrl = url;
        if (!/^https?:\\/\\//i.test(url) && !url.startsWith('/')) {
          targetUrl = specDir + url;
        }

        try {
          return await origHttp(bust(targetUrl), options);
        } catch (err) {
          if (targetUrl !== '/' + url && !/^https?:\\/\\//i.test(url)) {
            try {
              return await origHttp(bust('/' + url), options);
            } catch (_) {}
          }
          loadErrors.push(\`Failed to load data URL "\${url}": \${err.message || err}\`);
          throw err;
        }
      };
      return loader;
    }

    themeBtn.addEventListener('click', () => {
      useDarkTheme = !useDarkTheme;
      themeBtn.textContent = 'Chart Theme: ' + (useDarkTheme ? 'Dark' : 'Light');
      dialogViewport.classList.toggle('light-bg', !useDarkTheme);
      renderAll();
      if (dialog.open && currentModalKey) {
        openFullscreen(currentModalKey, false);
      }
    });

    async function renderSpecInto(container, item) {
      container.innerHTML = '';
      if (item.error) {
        container.innerHTML = \`<div class="error-box">JSON Error:\\n\${item.error}</div>\`;
        return false;
      }

      const loadErrors = [];
      const loader = createCustomLoader(item.relPath, loadErrors);

      try {
        await vegaEmbed(container, item.spec, {
          mode: item.mode,
          renderer: 'svg',
          loader,
          actions: { export: true, source: false, editor: false },
          theme: useDarkTheme ? 'dark' : undefined,
        });
        if (loadErrors.length > 0) {
          container.innerHTML = \`<div class="error-box">Data Load Error:\\n\${loadErrors.join('\\n')}</div>\`;
          return false;
        }
        return true;
      } catch (vgErr) {
        container.innerHTML = \`<div class="error-box">Vega Error:\\n\${vgErr.message}</div>\`;
        return false;
      }
    }

    async function renderAll() {
      try {
        const res = await fetch('/api/specs');
        const items = await res.json();
        statusEl.textContent = \`Synced (\${items.length} charts) at \${new Date().toLocaleTimeString()}\`;

        latestSpecs.clear();
        items.forEach(item => latestSpecs.set(item.relPath, item));

        const currentKeys = new Set(items.map(i => i.relPath));
        for (const [key, card] of activeViews.entries()) {
          if (!currentKeys.has(key)) {
            card.remove();
            activeViews.delete(key);
          }
        }

        // Render in sorted order
        for (const item of items) {
          let card = activeViews.get(item.relPath);
          if (!card) {
            card = document.createElement('section');
            card.className = 'card';
            card.innerHTML = \`
              <div class="card-title">
                <span>\${item.displayName}</span>
                <span class="badge">\${item.mode}</span>
              </div>
              <div class="chart-container" title="Click or tap to open fullscreen"></div>
            \`;
            const body = card.querySelector('.chart-container');
            body.addEventListener('click', (e) => {
              if (e.target.closest('.vega-actions') || e.target.closest('details')) return;
              openFullscreen(item.relPath, true);
            });
            activeViews.set(item.relPath, card);
          }

          // Ensure DOM order matches sorted order
          chartsEl.appendChild(card);

          const body = card.querySelector('.chart-container');
          body.classList.toggle('light-bg', !useDarkTheme);
          await renderSpecInto(body, item);
        }

        if (dialog.open && currentModalKey && latestSpecs.has(currentModalKey)) {
          await openFullscreen(currentModalKey, false);
        }
      } catch (err) {
        statusEl.textContent = 'Failed to fetch specs: ' + err.message;
      }
    }

    function applyZoom(newZoom) {
      const svg = dialogCanvas.querySelector('svg');
      if (!svg || !baseSvgSize.width || !baseSvgSize.height) return;

      currentZoom = Math.min(Math.max(newZoom, 0.2), 10);
      svg.style.width = \`\${Math.round(baseSvgSize.width * currentZoom)}px\`;
      svg.style.height = \`\${Math.round(baseSvgSize.height * currentZoom)}px\`;
      zoomLabel.textContent = \`\${Math.round(currentZoom * 100)}%\`;
    }

    function fitZoomToViewport() {
      if (!baseSvgSize.width || !baseSvgSize.height) return;
      const pad = 64;
      const availW = Math.max(dialogViewport.clientWidth - pad, 100);
      const availH = Math.max(dialogViewport.clientHeight - pad, 100);
      const scale = Math.min(availW / baseSvgSize.width, availH / baseSvgSize.height);
      applyZoom(scale);
    }

    async function openFullscreen(relPath, resetZoom = true) {
      const item = latestSpecs.get(relPath);
      if (!item) return;

      currentModalKey = relPath;
      dialogTitle.textContent = \`\${item.displayName} (\${item.mode})\`;
      dialogViewport.classList.toggle('light-bg', !useDarkTheme);

      if (!dialog.open) {
        dialog.showModal();
      }

      const ok = await renderSpecInto(dialogCanvas, item);
      if (!ok) return;

      const svg = dialogCanvas.querySelector('svg');
      if (svg) {
        const w = parseFloat(svg.getAttribute('width')) || svg.getBoundingClientRect().width || 600;
        const h = parseFloat(svg.getAttribute('height')) || svg.getBoundingClientRect().height || 400;
        if (!svg.getAttribute('viewBox')) {
          svg.setAttribute('viewBox', \`0 0 \${w} \${h}\`);
        }
        baseSvgSize = { width: w, height: h };

        if (resetZoom) {
          fitZoomToViewport();
        } else {
          applyZoom(currentZoom);
        }
      }
    }

    document.getElementById('zoomInBtn').addEventListener('click', () => applyZoom(currentZoom * 1.25));
    document.getElementById('zoomOutBtn').addEventListener('click', () => applyZoom(currentZoom / 1.25));
    document.getElementById('zoomResetBtn').addEventListener('click', () => applyZoom(1));
    document.getElementById('zoomFitBtn').addEventListener('click', () => fitZoomToViewport());
    document.getElementById('closeDialogBtn').addEventListener('click', () => dialog.close());

    dialogViewport.addEventListener('wheel', (e) => {
      if (!dialog.open) return;
      e.preventDefault();
      const factor = e.deltaY < 0 ? 1.12 : 1 / 1.12;
      applyZoom(currentZoom * factor);
    }, { passive: false });

    let isDragging = false;
    let startX = 0, startY = 0, scrollLeft = 0, scrollTop = 0;

    dialogViewport.addEventListener('mousedown', (e) => {
      if (e.button !== 0 || e.target.closest('details')) return;
      isDragging = true;
      dialogViewport.classList.add('dragging');
      startX = e.pageX - dialogViewport.offsetLeft;
      startY = e.pageY - dialogViewport.offsetTop;
      scrollLeft = dialogViewport.scrollLeft;
      scrollTop = dialogViewport.scrollTop;
    });

    window.addEventListener('mouseup', () => {
      isDragging = false;
      dialogViewport.classList.remove('dragging');
    });

    dialogViewport.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      e.preventDefault();
      const x = e.pageX - dialogViewport.offsetLeft;
      const y = e.pageY - dialogViewport.offsetTop;
      dialogViewport.scrollLeft = scrollLeft - (x - startX);
      dialogViewport.scrollTop = scrollTop - (y - startY);
    });

    const sse = new EventSource('/events');
    sse.onopen = () => { statusEl.textContent = 'Connected (Hot Reload Active)'; };
    sse.onerror = () => { statusEl.textContent = 'Disconnected, retrying...'; };
    sse.onmessage = (e) => {
      const data = JSON.parse(e.data);
      if (data.type === 'reload') renderAll();
    };

    renderAll();
  </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = decodeURIComponent(parsedUrl.pathname);

  if (pathname === '/' || pathname === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    return res.end(CLIENT_HTML);
  }

  if (pathname === '/api/specs') {
    res.writeHead(200, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-cache',
    });
    return res.end(JSON.stringify(getSpecs()));
  }

  if (pathname === '/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    });
    res.write('\n');
    clients.push(res);

    req.on('close', () => {
      clients = clients.filter((c) => c !== res);
    });
    return;
  }

  const safePath = path.resolve(ROOT_DIR, '.' + pathname);
  if (!safePath.startsWith(ROOT_DIR)) {
    res.writeHead(403);
    return res.end('Forbidden');
  }

  fs.stat(safePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      return res.end(`Not Found: ${pathname}`);
    }

    const ext = path.extname(safePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache',
      'Access-Control-Allow-Origin': '*',
    });
    fs.createReadStream(safePath).pipe(res);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Vega live server running at http://localhost:${PORT}`);
});

