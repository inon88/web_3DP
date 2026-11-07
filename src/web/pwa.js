// WEB: installable app + offline use (rancangan.md §5, §16). The service worker (dist/sw.js, built by
// scripts/service-worker.mjs) keeps the app's own files only. Production builds only: the dev server
// changes files all the time.
const RUNTIME_URL = /^(?:\/fonts\/|\/vtracer\/)/;
const GOOGLE_FONTS = 'https://fonts.gstatic.com';

let reloadRequested = false;

function showUpdateBanner(worker) {
  if (document.querySelector('.update-banner')) return;
  const banner = document.createElement('div');
  banner.className = 'update-banner';
  banner.setAttribute('role', 'status');
  const text = document.createElement('span');
  text.textContent = 'A new version of BonaStudio is available. Reloading clears the tools and images you added.';
  const reload = document.createElement('button');
  reload.className = 'button button-primary button-compact';
  reload.type = 'button';
  reload.textContent = 'Reload';
  reload.addEventListener('click', () => {
    reloadRequested = true;
    reload.disabled = true;
    worker.postMessage({ type: 'skip-waiting' });
  });
  const later = document.createElement('button');
  later.className = 'button button-secondary button-compact';
  later.type = 'button';
  later.textContent = 'Later';
  later.addEventListener('click', () => banner.remove());
  banner.append(text, later, reload);
  document.body.append(banner);
}

// Fonts and the tracer the page fetched before the worker controlled it (first visit) → its cache.
function handOverLoadedFiles(worker) {
  const urls = performance.getEntriesByType('resource')
    .map(entry => entry.name)
    .filter(name => {
      const url = new URL(name);
      return (url.origin === location.origin && RUNTIME_URL.test(url.pathname)) || url.origin === GOOGLE_FONTS;
    });
  if (urls.length) worker.postMessage({ type: 'cache-urls', urls: [...new Set(urls)] });
}

function watch(registration) {
  const offer = worker => {
    if (worker && navigator.serviceWorker.controller) showUpdateBanner(worker);
  };
  offer(registration.waiting);
  registration.addEventListener('updatefound', () => {
    const worker = registration.installing;
    worker?.addEventListener('statechange', () => {
      if (worker.state === 'installed') offer(worker);
    });
  });
  // Look for a new version whenever the app comes back to the foreground.
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') registration.update().catch(() => {});
  });
  navigator.serviceWorker.ready.then(ready => ready.active && handOverLoadedFiles(ready.active));
}

function setUpInstallButton() {
  const button = document.getElementById('installButton');
  if (!button) return;
  let deferred = null;
  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    deferred = event;
    button.hidden = false;
  });
  button.addEventListener('click', async () => {
    if (!deferred) return;
    button.hidden = true;
    deferred.prompt();
    await deferred.userChoice.catch(() => null);
    deferred = null;
  });
  window.addEventListener('appinstalled', () => { button.hidden = true; deferred = null; });
}

// engineEvents: start after the render engine has downloaded, so the worker copies it from the HTTP
// cache instead of downloading 11 MB a second time.
export function startPwa(engineEvents) {
  setUpInstallButton();
  if (!import.meta.env.PROD || !('serviceWorker' in navigator)) return;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (reloadRequested) location.reload();
  });
  let started = false;
  const register = () => {
    if (started) return;
    started = true;
    navigator.serviceWorker.register('/sw.js', { scope: '/' }).then(watch).catch(error => console.warn('Offline support is unavailable:', error));
  };
  if (engineEvents.status === 'ready' || engineEvents.status === 'error') register();
  else {
    engineEvents.addEventListener('ready', register, { once: true });
    engineEvents.addEventListener('error', register, { once: true });
    setTimeout(register, 30000);
  }
}
