const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const cacheKey = 'startpage-central-settings-v1';
const runtimeSource = fs.readFileSync(
  path.join(__dirname, '..', 'script', 'runtime-settings.js'),
  'utf8'
);

function settings(username) {
  return {
    _schemaVersion: 1,
    username,
    weatherLocation: 'Test City',
    weatherUnit: 'celsius',
    timezone: 'UTC',
    aiModeEnabled: false,
    aiRouteBadgeMode: 'live',
    searchEngine: 'brave',
    theme: 'stylix',
    bookmarks: [{ href: 'https://example.com', title: 'example' }],
    shelfBookmarks: [],
    syntaxColors: {},
    searchOverrides: {},
    customTags: [],
    dirExtensions: {},
    terminalPrompts: []
  };
}

function createRuntime(cached) {
  const values = new Map(cached ? [[cacheKey, JSON.stringify(cached)]] : []);
  let resolveFetch;
  const window = {
    STARTPAGE_USE_LOCAL_SETTINGS_CACHE: true,
    STARTPAGE_SETTINGS: {},
    localStorage: {
      getItem: key => values.get(key) ?? null,
      setItem: (key, value) => values.set(key, value),
      removeItem: key => values.delete(key)
    }
  };
  const context = vm.createContext({
    window,
    fetch: () => new Promise(resolve => {
      resolveFetch = resolve;
    }),
    console: { warn: () => {} },
    DEFAULT_USERNAME: 'default-user',
    DEFAULT_WEATHER_LOCATION: 'Default City',
    DEFAULT_WEATHER_UNIT: 'fahrenheit',
    DEFAULT_TIMEZONE: 'UTC',
    DEFAULT_AI_MODE_ENABLED: false,
    DEFAULT_AI_ROUTE_BADGE_MODE: 'live',
    DEFAULT_SEARCH_ENGINE: 'brave',
    DEFAULT_THEME: 'stylix',
    DEFAULT_BOOKMARKS: [{ href: 'https://default.example', title: 'default' }],
    DEFAULT_SHELF_BOOKMARKS: [],
    DEFAULT_SYNTAX_COLORS: {},
    THEMES: ['stylix'],
    isValidSearchEngine: value => ['brave', 'google', 'ddg', 'bing'].includes(value)
  });

  vm.runInContext(runtimeSource, context, { filename: 'runtime-settings.js' });
  return { context, values, window, resolveFetch: () => resolveFetch };
}

function response(body) {
  return {
    ok: true,
    json: async () => body
  };
}

function nextTurn() {
  return new Promise(resolve => setImmediate(resolve));
}

async function run() {
  const cached = createRuntime(settings('cached'));
  await cached.context.loadStartpageSettings();
  assert.equal(cached.window.STARTPAGE_SETTINGS.username, 'cached');
  assert.equal(cached.context.canSaveStartpageSettings(), true);

  cached.resolveFetch()(response(settings('fresh')));
  await nextTurn();
  assert.equal(JSON.parse(cached.values.get(cacheKey)).username, 'fresh');

  const uncached = createRuntime(null);
  await uncached.context.loadStartpageSettings();
  assert.equal(uncached.window.STARTPAGE_SETTINGS.username, 'default-user');
  assert.equal(uncached.context.canSaveStartpageSettings(), false);

  uncached.resolveFetch()(response(settings('synced')));
  await nextTurn();
  assert.equal(JSON.parse(uncached.values.get(cacheKey)).username, 'synced');
  assert.equal(uncached.context.canSaveStartpageSettings(), false);
}

run().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
