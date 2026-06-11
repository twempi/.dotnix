// ========================================
// Prompts Modal — Terminal placeholder suggestions editor
// ========================================

const DEFAULT_PROMPTS = [
  "search anything...",
  ":help → commands",
  ":config → settings",
  "ai:directions to home → maps",
  ":aimode → toggle no-prefix AI routing",
  "brave:query → brave search",
  "yt:query → youtube",
  "maps:location → google maps",
  "dir/books: dune → open directory",
  "dir/music/brave: flac albums → open dir on Brave",
];

// ---- Storage ----
function getStoredPrompts() {
  const prompts = getStartpageSetting('terminalPrompts', []);
  return Array.isArray(prompts) && prompts.length ? prompts : null;
}

function savePrompts(prompts) {
  notifyCentralSettingsReadOnly();
}

function clearStoredPrompts() {
  notifyCentralSettingsReadOnly();
}

// Returns whichever list is active (stored or defaults)
function getActivePrompts() {
  return getStoredPrompts() || DEFAULT_PROMPTS;
}

// ---- Modal ----
function openPromptsModal() {
  const textarea = document.getElementById('prompts-textarea');
  const prompts = getActivePrompts();
  textarea.value = prompts.join('\n');
  textarea.readOnly = true;
  textarea.title = CENTRAL_SETTINGS_HINT;
  ['btn-reset-prompts', 'btn-save-prompts'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.disabled = true;
      el.title = CENTRAL_SETTINGS_HINT;
    }
  });
  document.getElementById('prompts-modal').classList.add('active');
  textarea.focus();
}

function closePromptsModal() {
  document.getElementById('prompts-modal').classList.remove('active');
}

function savePromptsModal() {
  notifyCentralSettingsReadOnly();
}

function resetPromptsModal() {
  document.getElementById('prompts-textarea').value = getActivePrompts().join('\n');
  notifyCentralSettingsReadOnly();
}
