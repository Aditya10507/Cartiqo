{{flutter_js}}
{{flutter_build_config}}

const hostElement = document.getElementById('flutter_host');

async function clearLegacyCache() {
  if ('serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    } catch (_) {}
  }

  if ('caches' in window) {
    try {
      const cacheKeys = await caches.keys();
      await Promise.all(cacheKeys.map((key) => caches.delete(key)));
    } catch (_) {}
  }
}

(async function bootstrapCartiqo() {
  await clearLegacyCache();

  _flutter.loader.load({
    config: {
      hostElement,
    },
    onEntrypointLoaded: async function(engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    },
  });
})();
