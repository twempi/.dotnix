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
  return saveStartpageSettings({ terminalPrompts: prompts }, { successMessage: 'Prompts saved' });
}

function clearStoredPrompts() {
  return saveStartpageSettings({ terminalPrompts: [] }, { successMessage: 'Prompts reset' });
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
  textarea.readOnly = false;
  textarea.title = '';
  ['btn-reset-prompts', 'btn-save-prompts'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.disabled = false;
      el.title = '';
    }
  });
  document.getElementById('prompts-modal').classList.add('active');
  textarea.focus();
}

function closePromptsModal() {
  document.getElementById('prompts-modal').classList.remove('active');
}

async function savePromptsModal() {
  const prompts = document.getElementById('prompts-textarea').value
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean);

  try {
    await savePrompts(prompts);
    closePromptsModal();
  } catch (_) {
    // saveStartpageSettings already showed the error toast.
  }
}

async function resetPromptsModal() {
  document.getElementById('prompts-textarea').value = DEFAULT_PROMPTS.join('\n');
  try {
    await clearStoredPrompts();
  } catch (_) {
    // saveStartpageSettings already showed the error toast.
  }
}
