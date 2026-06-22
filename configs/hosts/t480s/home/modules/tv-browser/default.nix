{
  config,
  lib,
  pkgs,
  ...
}: let
  startpage = "https://t480s.tailae03d0.ts.net/";
  browserPackage = pkgs.chromium.override {
    enableWideVine = true;
  };
  browserDesktop = "chromium-browser.desktop";
in {
  programs.chromium = {
    enable = true;
    package = browserPackage;
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      "--disable-features=WaylandFractionalScaleV1"
      "--start-maximized"
    ];
  };

  home.sessionVariables = {
    BROWSER = "${config.programs.chromium.finalPackage}/bin/chromium";
    DEFAULT_BROWSER = "${config.programs.chromium.finalPackage}/bin/chromium";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ] (_: [browserDesktop]);
  };

  xdg.desktopEntries.tv-browser = {
    name = "TV Browser";
    genericName = "Web Browser";
    exec = "${config.programs.chromium.finalPackage}/bin/chromium --new-window ${startpage}";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
  };
}
