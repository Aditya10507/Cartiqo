{{flutter_js}}
{{flutter_build_config}}

const hostElement = document.getElementById('flutter_host');
const loadingShell = document.getElementById('loading_shell');
const loadingMessage = document.getElementById('loading_message');

function showLoaderMessage(message) {
  if (loadingMessage) {
    loadingMessage.textContent = message;
  }
}

window.addEventListener('error', function(event) {
  const details = event && event.message ? event.message : 'Unknown startup error';
  showLoaderMessage(`Startup error: ${details}`);
});

window.addEventListener('unhandledrejection', function(event) {
  const reason = event && event.reason ? event.reason : 'Unknown async startup error';
  showLoaderMessage(`Startup error: ${reason}`);
});

setTimeout(function() {
  showLoaderMessage('Startup is taking longer than expected');
}, 15000);

_flutter.loader.load({
  config: {
    hostElement,
    renderer: 'canvaskit',
    canvasKitVariant: 'full',
    canvasKitForceCpuOnly: true,
  },
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      showLoaderMessage('Starting Cartiqo...');
      const appRunner = await engineInitializer.initializeEngine();
      showLoaderMessage('Running app...');
      await appRunner.runApp();
      if (loadingShell) {
        loadingShell.remove();
      }
    } catch (error) {
      const message = error && error.message ? error.message : error;
      showLoaderMessage(`Startup error: ${message}`);
      console.error('Flutter bootstrap failed', error);
    }
  },
});
