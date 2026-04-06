{{flutter_js}}
{{flutter_build_config}}

const hostElement = document.getElementById('flutter_host');

_flutter.loader.load({
  config: {
    hostElement,
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});
