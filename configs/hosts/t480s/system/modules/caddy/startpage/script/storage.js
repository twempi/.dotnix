// ========================================
// Defaults
// ========================================
const DEFAULT_BOOKMARKS = [
  { href: "https://canvas.calpoly.edu/", title: "canvas" },
  { href: "https://outlook.office365.com/mail/", title: "outlook" },
  { href: "https://teams.microsoft.com/v2/", title: "teams" },
  { href: "https://cmsweb.pscs.calpoly.edu/psp/CSLOPRD/EMPLOYEE/SA/s/WEBLIB_HCX_GN.H_DASHBOARD.FieldFormula.IScript_Main?", title: "student center" },
  { href: "https://mycourses.pearson.com/course-home#/tab/active", title: "pearson" },
  { href: "https://mail.google.com/mail/u/1/#inbox=", title: "gmail" },
  { href: "https://calendar.google.com/calendar/u/1/r", title: "calendar" },
  { href: "https://github.com/twempi", title: "github" },
  { href: "https://youtube.com/", title: "youtube" },
  { href: "https://reddit.com/r/unixporn/", title: "unixp*rn" },
  { href: "https://wallhaven.cc/toplist?page=1", title: "wallhaven" },
  { href: "https://www.taobao.com/", title: "taobao" },
  { href: "https://chatgpt.com/", title: "chatgpt" },
  { href: "https://chat.deepseek.com/", title: "deepseek" },
  { href: "https://claude.ai/chats", title: "claude" },
  { href: "https://www.perplexity.ai/", title: "perplexity" },
  { href: "https://animekai.to/updates?page=1", title: "animekai" },
  { href: "https://anilist.co/home", title: "anilist" },
  { href: "https://suwayomi.tailae03d0.ts.net:8080/library", title: "reader" },
  { href: "https://mynixos.com/", title: "nix pakgs" },
  { href: "https://nix-community.github.io/stylix/index.html", title: "stylix" },
  { href: "https://leetcode.com/problemset/", title: "leetcode" },
  { href: "https://neetcode.io/practice/practice/neetcode150", title: "neetcode" },
  { href: "https://codingbat.com/python", title: "codingbat" }
];

const DEFAULT_USERNAME = "edward";
const DEFAULT_WEATHER_LOCATION = "Gurgaon";
const DEFAULT_WEATHER_UNIT = "celsius";
const DEFAULT_TIMEZONE = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
const DEFAULT_GEMINI_MODEL = "gemini-2.5-flash-lite";
const DEFAULT_GEMINI_SYSTEM_PROMPT = "";
const DEFAULT_AI_MODE_ENABLED = false;
const DEFAULT_AI_ROUTE_BADGE_MODE = "live";
const DEFAULT_SEARCH_ENGINE = "google"; // "google" | "ddg" | "bing"

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
function getStoredBookmarks() {
  try {
    const stored = localStorage.getItem('bookmarks');
    return stored ? JSON.parse(stored) : DEFAULT_BOOKMARKS;
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
  return localStorage.getItem('theme') || 'stylix';
}
function saveTheme(theme) {
  try {
    localStorage.setItem('theme', theme);
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
// Gemini
// ========================================

// Gemini API key is stored in extension storage (chrome.storage.local /
// browser.storage.local) when running as an extension, for security.
// ext-storage.js populates _cachedGeminiApiKey and resolves extStorageReady.
// On localhost (no extension API), we fall back to localStorage.

function getStoredGeminiApiKey() {
  // ext-storage.js sets this cache; falls back to localStorage on localhost
  if (typeof _cachedGeminiApiKey !== 'undefined') return _cachedGeminiApiKey;
  return localStorage.getItem('geminiApiKey') || '';
}

function normalizeGeminiApiKey(key) {
  return String(key || '').trim();
}

function saveGeminiApiKey(key) {
  const normalized = normalizeGeminiApiKey(key);

  // Extension: save to chrome.storage.local / browser.storage.local
  const extStorage = (typeof browser !== 'undefined' && browser?.storage?.local)
    ? browser.storage.local
    : (typeof chrome !== 'undefined' && chrome?.storage?.local)
      ? chrome.storage.local
      : null;

  if (extStorage) {
    // Update in-memory cache used by getStoredGeminiApiKey
    if (typeof _cachedGeminiApiKey !== 'undefined') {
      // _cachedGeminiApiKey is declared in ext-storage.js — update via its setter
      window._cachedGeminiApiKey = normalized;
    }
    localStorage.removeItem('geminiApiKey'); // never store in localStorage
    extStorage.set({ geminiApiKey: normalized });
    return;
  }

  // Localhost fallback
  localStorage.setItem('geminiApiKey', normalized);
}
function getStoredGeminiModel() {
  return localStorage.getItem('geminiModel') || DEFAULT_GEMINI_MODEL;
}
function saveGeminiModel(model) {
  localStorage.setItem('geminiModel', model);
}
function getStoredGeminiSystemPrompt() {
  return localStorage.getItem('geminiSystemPrompt') || DEFAULT_GEMINI_SYSTEM_PROMPT;
}
function saveGeminiSystemPrompt(prompt) {
  localStorage.setItem('geminiSystemPrompt', String(prompt || '').trim());
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
  'r':      { label: 'Reddit',        default: 'https://google.com/search?q=site:reddit.com ' },
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
function getStoredSearchEngine() {
  const stored = localStorage.getItem('searchEngine') || DEFAULT_SEARCH_ENGINE;
  return ['google', 'ddg', 'bing'].includes(stored) ? stored : DEFAULT_SEARCH_ENGINE;
}
function saveSearchEngine(engine) {
  const normalized = String(engine || '').toLowerCase();
  localStorage.setItem('searchEngine', ['google', 'ddg', 'bing'].includes(normalized) ? normalized : DEFAULT_SEARCH_ENGINE);
}
