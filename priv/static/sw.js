const CACHE_NAME = "dateapp-v3";
const OFFLINE_URL = "/offline.html";

const PRECACHE_ASSETS = [
  "/offline.html",
  "/images/icon-192.svg"
];

// Pages to NEVER cache (auth, CSRF-sensitive)
const NO_CACHE = ["/login", "/register", "/auth/"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Never intercept: non-GET, websockets, auth pages, POST requests
  if (
    request.method !== "GET" ||
    url.pathname.includes("/live/") ||
    NO_CACHE.some((path) => url.pathname.startsWith(path))
  ) {
    return;
  }

  // Static assets only: cache first
  if (
    url.pathname.startsWith("/assets/") ||
    url.pathname.startsWith("/images/") ||
    url.pathname.startsWith("/uploads/")
  ) {
    event.respondWith(
      caches.match(request).then((cached) => {
        const fetchPromise = fetch(request).then((response) => {
          if (response.ok) {
            caches.open(CACHE_NAME).then((cache) => cache.put(request, response.clone()));
          }
          return response;
        });
        return cached || fetchPromise;
      })
    );
    return;
  }

  // HTML pages: always network first, offline fallback only
  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).catch(() => caches.match(OFFLINE_URL))
    );
    return;
  }
});
