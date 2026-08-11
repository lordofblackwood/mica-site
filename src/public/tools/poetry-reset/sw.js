"use strict";

const CACHE_PREFIX = "mica-poetry-reset-";
const CACHE_VERSION = "v4";
const SHELL_CACHE = `${CACHE_PREFIX}${CACHE_VERSION}`;

const APP_ROOT = new URL("./", self.registration.scope);
const SHELL_URLS = [
  new URL("./", APP_ROOT).href,
  new URL("index.html", APP_ROOT).href,
  new URL("manifest.webmanifest", APP_ROOT).href,
  new URL("icon.svg", APP_ROOT).href,
  new URL("site.css", APP_ROOT).href,
  new URL("site.js", APP_ROOT).href,
  new URL("poetry-reset.js", APP_ROOT).href,
];
const SHELL_URL_SET = new Set(SHELL_URLS);

const cacheableResponse = (response) =>
  response && response.ok && response.type === "basic";

async function fetchAndCache(request, cacheName = SHELL_CACHE) {
  const response = await fetch(request);

  if (cacheableResponse(response)) {
    const cache = await caches.open(cacheName);
    await cache.put(request, response.clone());
  }

  return response;
}

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(SHELL_CACHE);

      // Reload bypasses an HTTP cache entry left by an older worker while the
      // new version is being prepared. A failed shell fetch keeps this worker
      // from replacing a known-good installed version.
      await Promise.all(
        SHELL_URLS.map(async (url) => {
          const request = new Request(url, { cache: "reload" });
          const response = await fetch(request);

          if (!cacheableResponse(response)) {
            throw new Error(`Unable to cache app shell resource: ${url}`);
          }

          await cache.put(url, response);
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter(
            (cacheName) =>
              cacheName.startsWith(CACHE_PREFIX) && cacheName !== SHELL_CACHE,
          )
          .map((cacheName) => caches.delete(cacheName)),
      );
      await self.clients.claim();
    })(),
  );
});

async function serveShellResource(request) {
  const cache = await caches.open(SHELL_CACHE);
  try {
    return await fetchAndCache(request);
  } catch (_) {
    return (await cache.match(request)) || Response.error();
  }
}

async function serveNavigation(request) {
  try {
    const response = await fetchAndCache(request);
    if (response.ok) return response;
  } catch (_) {
    // Fall back to the pre-cached app entry point below.
  }

  const cache = await caches.open(SHELL_CACHE);
  return (
    (await cache.match(request, { ignoreSearch: true })) ||
    (await cache.match(APP_ROOT.href)) ||
    (await cache.match(new URL("index.html", APP_ROOT).href)) ||
    Response.error()
  );
}

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  const inAppScope = url.href.startsWith(APP_ROOT.href);
  if (request.mode === "navigate" && inAppScope) {
    event.respondWith(serveNavigation(request));
    return;
  }

  if (SHELL_URL_SET.has(url.href)) {
    event.respondWith(serveShellResource(request));
  }

  // Everything else, including WebLLM model files and shards, stays outside
  // this cache. WebLLM can manage its own storage without a duplicate copy.
});

self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SKIP_WAITING") {
    self.skipWaiting();
  }
});
