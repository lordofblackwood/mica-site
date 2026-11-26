const root = self.registration.scope;
const cachePrefix = 'micaos-shell:' + root + ':';
const cacheName = cachePrefix + '2';
const files = ['index.html', 'manifest.webmanifest', 'icon.svg', 'icon-180.png', 'icon-192.png', 'icon-512.png'];
const urls = files.map(file => new URL(file, root).href);
const [home] = urls;

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const requests = urls.map(url => new Request(url, { cache: 'reload', redirect: 'error' }));
    const cache = await caches.open(cacheName);
    await cache.addAll(requests);
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(key => key.startsWith(cachePrefix) && key !== cacheName)
      .map(key => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  url.search = '';
  const key = url.href === root ? home : url.href;
  if (!urls.includes(key)) return;

  event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    let response;
    try {
      response = await fetch(event.request);
    } catch (error) {
      const saved = await cache.match(key);
      if (saved) return saved;
      throw error;
    }
    if (response.ok && !response.redirected && response.type === 'basic') {
      await cache.put(key, response.clone()).catch(() => {});
    }
    return response;
  })());
});
