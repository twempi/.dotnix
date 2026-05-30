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
  document.getElementById('config-modal').classList.add('active');
}

function closeConfig() {
  document.getElementById('config-modal').classList.remove('active');
}

function saveConfig() {
  const sanitize = (str) => typeof str === 'string' ? str.replace(/[<>]/g, '').trim() : '';

  const weatherInput = document.getElementById('weather-location');
  const timezoneInput = document.getElementById('time-zone');
  const usernameInput = document.getElementById('config-username');
  const aiModeEnabledInput = document.getElementById('ai-mode-enabled');
  const aiRouteBadgeModeInput = document.getElementById('ai-route-badge-mode');
  const searchEngineInput = document.getElementById('search-engine');

  const loc = sanitize(weatherInput.value) || (typeof DEFAULT_WEATHER_LOCATION !== 'undefined' ? DEFAULT_WEATHER_LOCATION : '');
  const tz = sanitize(timezoneInput.value) || (typeof DEFAULT_TIMEZONE !== 'undefined' ? DEFAULT_TIMEZONE : '');

  saveWeatherLocation(loc);
  saveTimezone(tz);
  if (usernameInput.value.trim()) saveUsername(usernameInput.value.trim());
  saveAiModeEnabled(!!aiModeEnabledInput.checked);
  saveAiRouteBadgeMode(aiRouteBadgeModeInput.value);
  saveSearchEngine(searchEngineInput.value);

  updateWeather();
  closeConfig();
  if (typeof hideAiRouteBadge === 'function') hideAiRouteBadge();
  document.getElementById('username').textContent = getStoredUsername();
  showToast('Configuration saved', 'success');
}
