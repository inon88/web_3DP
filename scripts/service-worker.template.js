// BonaStudio service worker (rancangan.md §16). Generated into dist/sw.js by scripts/service-worker.mjs:
// the version and the precache list are filled in at build time. It only ever stores the app's own files
// (UI, OpenSCAD engine, library, fonts); never anything a person adds or makes.
const VERSION = __VERSION__;
const PRECACHE = __PRECACHE__;
const CACHE = 'bonastudio-' + VERSION;
// Fonts and the image tracer are cached when first used (versioned paths, so they survive app updates).
const RUNTIME = 'bonastudio-runtime';
const RUNTIME_PATHS = /^\/(?:fonts|vtracer)\//;
const GOOGLE_FONTS = 'https://fonts.gstatic.com';
// Hashed or versioned paths never change content, so a copy from the previous version can be reused.
const IMMUTABLE_PATHS = /^\/(?:assets\/.+-[\w-]{8,}\.\w+|openscad\/|fonts\/|vtracer\/)/;

async function precache() {
  const cache = await caches.open(CACHE);
  for (const path of PRECACHE) {
    let response = IMMUTABLE_PATHS.test(path) ? await caches.match(path) : undefined;
    if (!response) {
      response = await fetch(path, { credentials: 'same-origin' });
      if (!response.ok) throw new Error(`Could not cache ${path} (HTTP ${response.status}).`);
    }
    await cache.put(path, response);
  }
}

self.addEventListener('install', event => {
  event.waitUntil(precache().then(() => {
    // First install: take over the open page right away. Updates wait for the page's "Reload".
    if (!self.registration.active) return self.skipWaiting();
  }));
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('bonastudio-') && key !== CACHE && key !== RUNTIME) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

async function cacheRuntime(urls) {
  const cache = await caches.open(RUNTIME);
  for (const url of urls) {
    if (await cache.match(url)) continue;
    try {
      const response = await fetch(url, { mode: 'cors', credentials: 'omit' });
      if (response.ok) await cache.put(url, response);
    } catch {
      // Offline or blocked: it is cached on its next use instead.
    }
  }
}

self.addEventListener('message', event => {
  if (event.data?.type === 'skip-waiting') self.skipWaiting();
  // Files the page loaded before this worker controlled it (first visit).
  if (event.data?.type === 'cache-urls' && Array.isArray(event.data.urls)) {
    const urls = event.data.urls.filter(url => isRuntimeUrl(new URL(url, self.location.origin))).slice(0, 200);
    event.waitUntil(cacheRuntime(urls));
  }
});

function isRuntimeUrl(url) {
  return (url.origin === self.location.origin && RUNTIME_PATHS.test(url.pathname)) || url.origin === GOOGLE_FONTS;
}

async function fromRuntimeCache(request) {
  const cache = await caches.open(RUNTIME);
  const cached = await cache.match(request.url);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok) cache.put(request.url, response.clone()).catch(() => {});
  return response;
}

self.addEventListener('fetch', event => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (request.mode === 'navigate' && url.origin === self.location.origin) {
    // The app is one page: every navigation gets the cached shell, so it opens offline.
    event.respondWith(caches.match('/', { cacheName: CACHE }).then(response => response || fetch(request)));
    return;
  }
  if (url.origin === self.location.origin && PRECACHE.includes(url.pathname)) {
    event.respondWith(caches.match(url.pathname, { cacheName: CACHE }).then(response => response || fetch(request)));
    return;
  }
  if (isRuntimeUrl(url)) event.respondWith(fromRuntimeCache(request));
  // Everything else (links people import from) goes to the network untouched.
});
