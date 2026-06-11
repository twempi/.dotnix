// ========================================
// Config Modal
// ========================================
function openConfig() {
  document.getElementById('weather-location').value = getStoredWeatherLocation();
  document.getElementById('time-zone').value = getStoredTimezone();
  document.getElementById('config-username').value = getStoredUsername();
  document.getElementById('ai-mode-enabled').checked = getStoredAiModeEnabled();
  document.getElementById('ai-route-badge-mode').value = getStoredAiRouteBadgeMode();
  document.getElementById('search-engine').value = getStoredSearchEngine();
  _setConfigReadOnly();
  document.getElementById('config-modal').classList.add('active');
}

function closeConfig() {
  document.getElementById('config-modal').classList.remove('active');
}

function saveConfig() {
  notifyCentralSettingsReadOnly();
}

function _setConfigReadOnly() {
  [
    'config-username',
    'weather-location',
    'weather-unit',
    'time-zone',
    'ai-mode-enabled',
    'ai-route-badge-mode',
    'search-engine'
  ].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.disabled = true;
  });

  ['btn-save-config'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.disabled = true;
      el.title = CENTRAL_SETTINGS_HINT;
    }
  });
}
