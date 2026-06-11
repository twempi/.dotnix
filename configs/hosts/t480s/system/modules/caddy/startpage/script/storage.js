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
const DEFAULT_WEATHER_LOCATION = "San Luis Obispo";
const DEFAULT_WEATHER_UNIT = "fahrenheit";
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
const CENTRAL_SETTINGS_HINT = "Edit /var/lib/startpage/settings.json on the t480s, then refresh.";

function cloneSettingValue(value) {
  if (value === undefined) return undefined;
  return JSON.parse(JSON.stringify(value));
}

function getStartpageSetting(key, fallback) {
  const settings = window.STARTPAGE_SETTINGS || {};
  if (Object.prototype.hasOwnProperty.call(settings, key)) {
    return cloneSettingValue(settings[key]);
  }
  return cloneSettingValue(fallback);
}

function notifyCentralSettingsReadOnly() {
  if (typeof showToast === 'function') {
    showToast(`Central settings are read-only here. ${CENTRAL_SETTINGS_HINT}`, 'info', 5000);
  }
}

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
  return { ...defaults, ...getStartpageSetting('syntaxColors', {}) };
}
function saveSyntaxColors(colors) {
  notifyCentralSettingsReadOnly();
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
  return applyDefaultBookmarkCategories(getStartpageSetting('bookmarks', DEFAULT_BOOKMARKS));
}
function saveBookmarks(bookmarks) {
  if (!Array.isArray(bookmarks)) throw new Error('Invalid bookmarks data');
  notifyCentralSettingsReadOnly();
}

// ========================================
// Shelf Bookmarks (hidden, surface on filter)
// ========================================
function getStoredShelfBookmarks() {
  return getStartpageSetting('shelfBookmarks', DEFAULT_SHELF_BOOKMARKS);
}
function saveShelfBookmarks(bookmarks) {
  if (!Array.isArray(bookmarks)) throw new Error('Invalid shelf bookmarks data');
  notifyCentralSettingsReadOnly();
}

// ========================================
// Username
// ========================================
function getStoredUsername() {
  return getStartpageSetting('username', DEFAULT_USERNAME);
}
function saveUsername(name) {
  if (!name || typeof name !== 'string') throw new Error('Invalid username');
  notifyCentralSettingsReadOnly();
}

// ========================================
// Theme
// ========================================
function getStoredTheme() {
  return getStartpageSetting('theme', DEFAULT_THEME);
}
function saveTheme() {
  notifyCentralSettingsReadOnly();
}

// ========================================
// Weather / Timezone
// ========================================
function getStoredWeatherLocation() {
  return getStartpageSetting('weatherLocation', DEFAULT_WEATHER_LOCATION);
}
function saveWeatherLocation(location) {
  notifyCentralSettingsReadOnly();
}
function getStoredWeatherUnit() {
  return getStartpageSetting('weatherUnit', DEFAULT_WEATHER_UNIT);
}
function saveWeatherUnit(unit) {
  notifyCentralSettingsReadOnly();
}
function getStoredTimezone() {
  return getStartpageSetting('timezone', DEFAULT_TIMEZONE);
}
function saveTimezone(tz) {
  notifyCentralSettingsReadOnly();
}

// ========================================
// AI Router
// ========================================
function getStoredAiModeEnabled() {
  return getStartpageSetting('aiModeEnabled', DEFAULT_AI_MODE_ENABLED);
}
function saveAiModeEnabled(enabled) {
  notifyCentralSettingsReadOnly();
}
function getStoredAiRouteBadgeMode() {
  const mode = String(getStartpageSetting('aiRouteBadgeMode', DEFAULT_AI_ROUTE_BADGE_MODE)).toLowerCase();
  return ['live', 'route', 'off'].includes(mode) ? mode : DEFAULT_AI_ROUTE_BADGE_MODE;
}
function saveAiRouteBadgeMode(mode) {
  notifyCentralSettingsReadOnly();
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
  return getStartpageSetting('searchOverrides', {});
}
function saveSearchOverrides(overrides) {
  notifyCentralSettingsReadOnly();
}

// ========================================
// Custom Tags — user-defined prefix:url pairs
// ========================================
function getStoredCustomTags() {
  return getStartpageSetting('customTags', []);
}
function saveCustomTags(tags) {
  notifyCentralSettingsReadOnly();
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
  const stored = getStartpageSetting('searchEngine', DEFAULT_SEARCH_ENGINE);
  return isValidSearchEngine(stored) ? stored : DEFAULT_SEARCH_ENGINE;
}
function saveSearchEngine(engine) {
  notifyCentralSettingsReadOnly();
}
