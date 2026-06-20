// ========================================
// Config Modal
// ========================================
function openConfig() {
  document.getElementById('weather-location').value = getStoredWeatherLocation();
  document.getElementById('weather-unit').value = getStoredWeatherUnit();
  document.getElementById('time-zone').value = getStoredTimezone();
  document.getElementById('config-username').value = getStoredUsername();
  document.getElementById('ai-mode-enabled').checked = getStoredAiModeEnabled();
  document.getElementById('ai-route-badge-mode').value = getStoredAiRouteBadgeMode();
  document.getElementById('search-engine').value = getStoredSearchEngine();
  document.getElementById('config-modal').classList.add('active');
}

function closeConfig() {
  document.getElementById('config-modal').classList.remove('active');
}

async function saveConfig() {
  const timezone = document.getElementById('time-zone').value.trim();

  try {
    await saveStartpageSettings({
      username: document.getElementById('config-username').value.trim(),
      weatherLocation: document.getElementById('weather-location').value.trim(),
      weatherUnit: document.getElementById('weather-unit').value,
      timezone: timezone || null,
      aiModeEnabled: document.getElementById('ai-mode-enabled').checked,
      aiRouteBadgeMode: document.getElementById('ai-route-badge-mode').value,
      searchEngine: document.getElementById('search-engine').value
    }, { successMessage: 'Configuration saved' });

    if (typeof initializeBrowserInfo === 'function') initializeBrowserInfo();
    if (typeof updateTime === 'function') updateTime();
    if (typeof updateWeather === 'function') updateWeather();
    closeConfig();
  } catch (_) {
    // saveStartpageSettings already showed the error toast.
  }
}
