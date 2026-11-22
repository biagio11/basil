{{flutter_js}}
{{flutter_build_config}}

// Everything (engine, fonts) is served from this site: no third-party CDN.
// The engine's last-resort fonts are fetched from this site, not Google.
const basilConfig = { fontFallbackBaseUrl: 'fonts/' };

_flutter.loader.load({
  config: basilConfig,
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine(basilConfig);
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (splash) {
      splash.classList.add('out');
      setTimeout(function () { splash.remove(); }, 500);
    }
  },
});
