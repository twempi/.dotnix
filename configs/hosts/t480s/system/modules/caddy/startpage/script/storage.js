// ========================================
// Defaults
// ========================================
const DEFAULT_BOOKMARKS = [
  { href: "https://canvas.calpoly.edu/", title: "canvas", category: "school" },
  { href: "https://outlook.office365.com/mail/", title: "outlook", category: "school" },
  { href: "https://teams.microsoft.com/v2/", title: "teams", category: "school" },
  { href: "https://cmsweb.pscs.calpoly.edu/psp/CSLOPRD/EMPLOYEE/SA/s/WEBLIB_HCX_GN.H_DASHBOARD.FieldFormula.IScript_Main?", title: "student center", category: "school" },
  { href: "https://mycourses.pearson.com/course-home#/tab/active", title: "pearson", category: "school" },
  { href: "https://mail.google.com/mail/u/1/#inbox=", title: "gmail", category: "personal" },
  { href: "https://calendar.google.com/calendar/u/1/r", title: "calendar", category: "personal" },
  { href: "https://github.com/twempi", title: "github", category: "personal" },
  { href: "https://youtube.com/", title: "youtube", category: "fun" },
  { href: "https://reddit.com/r/unixporn/", title: "unixp*rn", category: "fun" },
  { href: "https://wallhaven.cc/toplist?page=1", title: "wallhaven", category: "fun" },
  { href: "https://www.taobao.com/", title: "taobao", category: "fun" },
  { href: "https://chatgpt.com/", title: "chatgpt", category: "ai" },
  { href: "https://chat.deepseek.com/", title: "deepseek", category: "ai" },
  { href: "https://claude.ai/chats", title: "claude", category: "ai" },
  { href: "https://www.perplexity.ai/", title: "perplexity", category: "ai" },
  { href: "https://animekai.to/updates?page=1", title: "animekai", category: "anime" },
  { href: "https://anilist.co/home", title: "anilist", category: "anime" },
  { href: "https://suwayomi.tailae03d0.ts.net:8080/library", title: "reader", category: "anime" },
  { href: "https://mynixos.com/", title: "nix pakgs", category: "linux" },
  { href: "https://nix-community.github.io/stylix/index.html", title: "stylix", category: "linux" },
  { href: "https://leetcode.com/problemset/", title: "leetcode", category: "coding" },
  { href: "https://neetcode.io/practice/practice/neetcode150", title: "neetcode", category: "coding" },
  { href: "https://codingbat.com/python", title: "codingbat", category: "coding" }
];

const DEFAULT_USERNAME = "edward";
const DEFAULT_WEATHER_LOCATION = "Gurgaon";
const DEFAULT_WEATHER_UNIT = "celsius";
const DEFAULT_TIMEZONE = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
const DEFAULT_AI_MODE_ENABLED = false;
const DEFAULT_AI_ROUTE_BADGE_MODE = "live";
const DEFAULT_SEARCH_ENGINE = "brave"; // "brave" | "google" | "ddg" | "bing"
const DEFAULT_THEME = "stylix";
const SEARCH_ENGINE_IDS = ["brave", "google", "ddg", "bing"];
const SEARCH_ENGINE_LABELS = {
  brave: "Brave",
  google: "Google",
  ddg: "DuckDuckGo",
  bing: "Bing"
};

const DEFAULT_SHELF_BOOKMARKS = [];

// ========================================
// Syntax Colors — universal, theme-independent
// ========================================
const DEFAULT_SYNTAX_COLORS = {
  cmd:     '#667eea', // :commands
  theme:   '#f6ad55', // :theme commands
  search:  '#f39c12', // search prefixes (yt:, maps:, etc.)
  version: '#00b894', // :version
  url:     '#5fafaf', // direct URLs (chess.com)
  unknown: '#e74c3c', // unrecognised :commands
};

function getDefaultSyntaxColors() {
  return {
    ...DEFAULT_SYNTAX_COLORS,
    ...(window.STARTPAGE_DEFAULT_SYNTAX_COLORS || {})
  };
}

function getStoredSyntaxColors() {
  const defaults = getDefaultSyntaxColors();
  try {
    const stored = localStorage.getItem('syntaxColors');
    if (!stored) return { ...defaults };
    return { ...defaults, ...JSON.parse(stored) };
  } catch (e) {
    return { ...defaults };
  }
}
function saveSyntaxColors(colors) {
  try {
    localStorage.setItem('syntaxColors', JSON.stringify(colors));
  } catch (e) { console.error('Failed to save syntax colors:', e); }
}
function applySyntaxColors(colors) {
  const defaults = getDefaultSyntaxColors();
  const root = document.documentElement;
  root.style.setProperty('--syn-cmd',     colors.cmd     || defaults.cmd);
  root.style.setProperty('--syn-theme',   colors.theme   || defaults.theme);
  root.style.setProperty('--syn-search',  colors.search  || defaults.search);
  root.style.setProperty('--syn-version', colors.version || defaults.version);
  root.style.setProperty('--syn-url',     colors.url     || defaults.url);
  root.style.setProperty('--syn-unknown', colors.unknown || defaults.unknown);
}

// ========================================
// Bookmarks
// ========================================
function applyDefaultBookmarkCategories(bookmarks) {
  const categoriesByHref = new Map(
    DEFAULT_BOOKMARKS
      .filter(bookmark => bookmark.href && bookmark.category)
      .map(bookmark => [bookmark.href, bookmark.category])
  );

  return bookmarks.map(bookmark => {
    if (!bookmark || typeof bookmark !== 'object' || bookmark.category) return bookmark;
    const category = categoriesByHref.get(bookmark.href);
    return category ? { ...bookmark, category } : bookmark;
  });
}

function getStoredBookmarks() {
  try {
    const stored = localStorage.getItem('bookmarks');
    return stored ? applyDefaultBookmarkCategories(JSON.parse(stored)) : DEFAULT_BOOKMARKS;
  } catch (e) {
    console.error('Failed to parse bookmarks:', e);
    return DEFAULT_BOOKMARKS;
  }
}
function saveBookmarks(bookmarks) {
  if (!Array.isArray(bookmarks)) throw new Error('Invalid bookmarks data');
  try {
    localStorage.setItem('bookmarks', JSON.stringify(bookmarks));
  } catch (e) {
    console.error('Failed to save bookmarks:', e);
    showToast('Could not save bookmarks. Storage may be full.', 'error', 4000);
  }
}

// ========================================
// Shelf Bookmarks (hidden, surface on filter)
// ========================================
function getStoredShelfBookmarks() {
  try {
    const stored = localStorage.getItem('shelfBookmarks');
    return stored ? JSON.parse(stored) : DEFAULT_SHELF_BOOKMARKS;
  } catch (e) {
    console.error('Failed to parse shelf bookmarks:', e);
    return DEFAULT_SHELF_BOOKMARKS;
  }
}
function saveShelfBookmarks(bookmarks) {
  if (!Array.isArray(bookmarks)) throw new Error('Invalid shelf bookmarks data');
  try {
    localStorage.setItem('shelfBookmarks', JSON.stringify(bookmarks));
  } catch (e) {
    console.error('Failed to save shelf bookmarks:', e);
    showToast('Could not save shelf bookmarks. Storage may be full.', 'error', 4000);
  }
}

// ========================================
// Username
// ========================================
function getStoredUsername() {
  return localStorage.getItem('username') || DEFAULT_USERNAME;
}
function saveUsername(name) {
  if (!name || typeof name !== 'string') throw new Error('Invalid username');
  try {
    localStorage.setItem('username', name.trim());
  } catch (e) {
    console.error('Failed to save username:', e);
  }
}

// ========================================
// Theme
// ========================================
function getStoredTheme() {
  return DEFAULT_THEME;
}
function saveTheme() {
  try {
    localStorage.setItem('theme', DEFAULT_THEME);
  } catch (e) {
    console.error('Failed to save theme:', e);
  }
}

// ========================================
// Weather / Timezone
// ========================================
function getStoredWeatherLocation() {
  return localStorage.getItem('weatherLocation') || DEFAULT_WEATHER_LOCATION;
}
function saveWeatherLocation(location) {
  try {
    localStorage.setItem('weatherLocation', location);
  } catch (e) { console.error(e); }
}
function getStoredWeatherUnit() {
  return localStorage.getItem('weatherUnit') || DEFAULT_WEATHER_UNIT;
}
function saveWeatherUnit(unit) {
  try {
    localStorage.setItem('weatherUnit', unit);
  } catch (e) { console.error(e); }
}
function getStoredTimezone() {
  return localStorage.getItem('timezone') || DEFAULT_TIMEZONE;
}
function saveTimezone(tz) {
  try {
    localStorage.setItem('timezone', tz);
  } catch (e) { console.error(e); }
}

// ========================================
// AI Router
// ========================================
function getStoredAiModeEnabled() {
  const stored = localStorage.getItem('aiModeEnabled');
  if (stored === null) return DEFAULT_AI_MODE_ENABLED;
  return stored === 'true';
}
function saveAiModeEnabled(enabled) {
  localStorage.setItem('aiModeEnabled', enabled ? 'true' : 'false');
}
function getStoredAiRouteBadgeMode() {
  const mode = (localStorage.getItem('aiRouteBadgeMode') || DEFAULT_AI_ROUTE_BADGE_MODE).toLowerCase();
  return ['live', 'route', 'off'].includes(mode) ? mode : DEFAULT_AI_ROUTE_BADGE_MODE;
}
function saveAiRouteBadgeMode(mode) {
  const normalized = String(mode || '').toLowerCase();
  localStorage.setItem('aiRouteBadgeMode', ['live', 'route', 'off'].includes(normalized) ? normalized : DEFAULT_AI_ROUTE_BADGE_MODE);
}

// ========================================
// Search Overrides — per-prefix URL overrides
// ========================================
const OVERRIDEABLE_PREFIXES = {
  'yt':     { label: 'YouTube',       default: 'https://www.youtube.com/results?search_query=' },
  'r':      { label: 'Reddit',        default: 'https://search.brave.com/search?q=site%3Areddit.com%20' },
  'brave':  { label: 'Brave',         default: 'https://search.brave.com/search?q=' },
  'ddg':    { label: 'DuckDuckGo',    default: 'https://duckduckgo.com/?q=' },
  'bing':   { label: 'Bing',          default: 'https://www.bing.com/search?q=' },
  'ggl':    { label: 'Google',        default: 'https://www.google.com/search?q=' },
  'amazon': { label: 'Amazon',        default: 'https://www.amazon.com/s?k=' },
  'imdb':   { label: 'IMDb',          default: 'https://www.imdb.com/find?q=' },
  'alt':    { label: 'AlternativeTo', default: 'https://alternativeto.net/browse/search/?q=' },
  'maps':   { label: 'Maps',          default: 'https://www.google.com/maps/search/' },
};

function getStoredSearchOverrides() {
  try {
    const stored = localStorage.getItem('searchOverrides');
    return stored ? JSON.parse(stored) : {};
  } catch (e) { return {}; }
}
function saveSearchOverrides(overrides) {
  try { localStorage.setItem('searchOverrides', JSON.stringify(overrides)); }
  catch (e) { console.error('Failed to save search overrides:', e); }
}

// ========================================
// Custom Tags — user-defined prefix:url pairs
// ========================================
function getStoredCustomTags() {
  try {
    const stored = localStorage.getItem('customTags');
    return stored ? JSON.parse(stored) : [];
  } catch (e) { return []; }
}
function saveCustomTags(tags) {
  try { localStorage.setItem('customTags', JSON.stringify(tags)); }
  catch (e) { console.error('Failed to save custom tags:', e); }
}
function isValidSearchEngine(engine) {
  return SEARCH_ENGINE_IDS.includes(String(engine || '').toLowerCase());
}
function getSearchEngineLabel(engine) {
  return SEARCH_ENGINE_LABELS[engine] || SEARCH_ENGINE_LABELS[DEFAULT_SEARCH_ENGINE];
}
function buildSearchUrl(engine, query) {
  const normalized = isValidSearchEngine(engine) ? String(engine).toLowerCase() : DEFAULT_SEARCH_ENGINE;
  const q = encodeURIComponent(query);
  if (normalized === 'google') return `https://google.com/search?q=${q}`;
  if (normalized === 'ddg') return `https://duckduckgo.com/?q=${q}`;
  if (normalized === 'bing') return `https://www.bing.com/search?q=${q}`;
  return `https://search.brave.com/search?q=${q}`;
}
function getStoredSearchEngine() {
  const stored = localStorage.getItem('searchEngine') || DEFAULT_SEARCH_ENGINE;
  return isValidSearchEngine(stored) ? stored : DEFAULT_SEARCH_ENGINE;
}
function saveSearchEngine(engine) {
  const normalized = String(engine || '').toLowerCase();
  localStorage.setItem('searchEngine', isValidSearchEngine(normalized) ? normalized : DEFAULT_SEARCH_ENGINE);
}
