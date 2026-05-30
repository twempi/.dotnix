(function redirectWithThemeShell() {
  try {
    const stylixBackground = '__STYLIX_BACKGROUND__'.startsWith('#') ? '__STYLIX_BACKGROUND__' : '#000000';
    document.documentElement.style.backgroundColor = stylixBackground;
    document.documentElement.style.colorScheme = 'dark';
  } catch (e) {}

  // Use absolute extension URL so it resolves correctly regardless of folder depth
  const root = (typeof chrome !== 'undefined' && chrome.runtime)
    ? chrome.runtime.getURL('index.html')
    : (typeof browser !== 'undefined' && browser.runtime)
      ? browser.runtime.getURL('index.html')
      : '../index.html'; // localhost fallback

  window.location.replace(root);
})();
