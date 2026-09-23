// Padel Scoreboard PWA Service Worker
const APP_VERSION = 'v1.6.7';
const CACHE_NAME = `padel-scoreboard-${APP_VERSION}`;

const PRECACHE_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'version.json',
  'favicon.png',
  'favicon.ico',
  'apple-touch-icon.png',
  'icon-192.png',
  'icon-512.png',
  'qr_app.png',
  'qr_rules.png'
];

// Install: Cache essential app assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS);
    }).then(() => {
      return self.skipWaiting();
    })
  );
});

// Activate: Clean up previous version caches and claim clients
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith('padel-scoreboard-') && name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});

// Fetch: Network-first for HTML/JSON (so updates arrive immediately), cache-first for images/fonts
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Only handle GET requests for same origin or fonts
  if (event.request.method !== 'GET') return;

  // Network-first for HTML and version.json to ensure immediate updates
  if (event.request.mode === 'navigate' || url.pathname.endsWith('.html') || url.pathname.endsWith('version.json') || url.pathname.endsWith('.json')) {
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseClone);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          return caches.match(event.request).then((cachedResponse) => {
            return cachedResponse || caches.match('index.html');
          });
        })
    );
    return;
  }

  // Stale-while-revalidate for static assets (icons, styles, scripts)
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      const fetchPromise = fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseClone);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          // Ignore offline fetch errors for static assets
        });

      return cachedResponse || fetchPromise;
    })
  );
});

// Listen for message from client to skip waiting
self.addEventListener('message', (event) => {
  if (event.data && (event.data.action === 'skipWaiting' || event.data.type === 'SKIP_WAITING')) {
    self.skipWaiting();
  }
});
