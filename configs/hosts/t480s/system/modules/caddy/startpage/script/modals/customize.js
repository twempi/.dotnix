// ========================================
// Customize Modal — Syntax Colors + Theme Switcher
// ========================================

const SYNTAX_COLOR_DEFS = [
  { key: 'cmd',     label: ':commands',       example: ':config'   },
  { key: 'theme',   label: ':theme commands', example: ':stylix'   },
  { key: 'search',  label: 'search prefixes', example: 'yt:query'  },
  { key: 'version', label: ':version',        example: ':version'  },
  { key: 'url',     label: 'direct URLs',     example: 'chess.com' },
  { key: 'unknown', label: 'unknown command', example: ':???'      },
];

const THEME_DEFS = [
  { value: 'stylix', label: 'Stylix' },
];

// ---- Open / Close ----
function openCustomizeModal() {
  _renderCustomizeModal();
  ['btn-reset-colors', 'btn-save-customize'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.disabled = true;
      el.title = CENTRAL_SETTINGS_HINT;
    }
  });
  document.getElementById('customize-modal').classList.add('active');
  const first = document.querySelector('#customize-modal .customize-hex');
  if (first) first.focus();
}

function closeCustomizeModal() {
  document.getElementById('customize-modal').classList.remove('active');
}

// ---- Render ----
function _renderCustomizeModal() {
  const colors = getStoredSyntaxColors();
  const currentTheme = getStoredTheme();

  // ---- Syntax color rows ----
  const grid = document.getElementById('customize-color-grid');
  grid.innerHTML = '';

  SYNTAX_COLOR_DEFS.forEach(({ key, label, example }) => {
    const defaults = getDefaultSyntaxColors();
    const color = colors[key] || defaults[key];

    const row = document.createElement('div');
    row.className = 'customize-row';
    row.dataset.key = key;

    row.innerHTML = `
      <span class="customize-label">${label}</span>
      <span class="customize-preview" style="color:${color}">${example}</span>
      <div class="customize-color-wrap">
        <input type="color" class="customize-swatch" value="${color}" data-key="${key}" title="Pick color">
        <input type="text" class="customize-hex" value="${color.toUpperCase()}" data-key="${key}" maxlength="7" spellcheck="false">
      </div>
      <button class="customize-reset-btn" data-key="${key}" title="Reset">↺</button>
    `;

    const swatch = row.querySelector('.customize-swatch');
    const hex    = row.querySelector('.customize-hex');
    const preview = row.querySelector('.customize-preview');
    const resetBtn = row.querySelector('.customize-reset-btn');

    swatch.disabled = true;
    swatch.title = CENTRAL_SETTINGS_HINT;
    hex.readOnly = true;
    hex.title = CENTRAL_SETTINGS_HINT;
    resetBtn.disabled = true;
    resetBtn.title = CENTRAL_SETTINGS_HINT;

    swatch.addEventListener('input', () => {
      const v = swatch.value;
      hex.value = v.toUpperCase();
      preview.style.color = v;
      _applyLiveColor(key, v);
    });

    hex.addEventListener('input', () => {
      const v = hex.value.trim();
      if (/^#[0-9a-f]{6}$/i.test(v)) {
        swatch.value = v;
        preview.style.color = v;
        _applyLiveColor(key, v);
      }
    });

    hex.addEventListener('blur', () => {
      let v = hex.value.trim();
      if (!v.startsWith('#')) v = '#' + v;
      if (/^#[0-9a-f]{6}$/i.test(v)) {
        hex.value = v.toUpperCase();
        swatch.value = v;
        preview.style.color = v;
        _applyLiveColor(key, v);
      } else {
        const stored = getStoredSyntaxColors();
        const defaults = getDefaultSyntaxColors();
        hex.value = (stored[key] || defaults[key]).toUpperCase();
        swatch.value = stored[key] || defaults[key];
        preview.style.color = stored[key] || defaults[key];
      }
    });

    resetBtn.addEventListener('click', () => {
      const def = getDefaultSyntaxColors()[key];
      swatch.value = def;
      hex.value = def.toUpperCase();
      preview.style.color = def;
      _applyLiveColor(key, def);
    });

    grid.appendChild(row);
  });

  // ---- Theme buttons ----
  const themeGrid = document.getElementById('customize-theme-grid');
  themeGrid.innerHTML = '';

  THEME_DEFS.forEach(({ value, label }) => {
    const btn = document.createElement('button');
    btn.className = 'customize-theme-btn' + (value === currentTheme ? ' active-theme' : '');
    btn.textContent = label;
    btn.disabled = true;
    btn.title = CENTRAL_SETTINGS_HINT;
    btn.addEventListener('click', () => {
      _applyTheme(value);
      themeGrid.querySelectorAll('.customize-theme-btn').forEach(b => b.classList.remove('active-theme'));
      btn.classList.add('active-theme');
    });
    themeGrid.appendChild(btn);
  });
}

function _applyLiveColor(key, value) {
  document.documentElement.style.setProperty(`--syn-${key}`, value);
}

function _applyTheme(theme) {
  THEMES.forEach(t => {
    document.body.classList.remove(`${t}-mode`);
    document.documentElement.classList.remove(`${t}-mode`);
  });
  document.body.classList.add('stylix-mode');
  document.documentElement.classList.add('stylix-mode');
  saveTheme(theme);
}

// ---- Save ----
function saveCustomize() {
  notifyCentralSettingsReadOnly();
}

// ---- Reset all syntax colors ----
async function resetAllSyntaxColors() {
  notifyCentralSettingsReadOnly();
}
