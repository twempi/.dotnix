{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  startpageOrigin = "https://t480s.tailae03d0.ts.net";
  heliumProfileDir = "Profile";

  extensions = import ./extensions {
    inherit config lib pkgs startpageOrigin;
  };

  heliumFlags = [
    "--profile-directory=${heliumProfileDir}"
    "--force-dark-mode"
    "--load-extension=${lib.concatStringsSep "," (map toString extensions.unpackedPaths)}"
  ];

  heliumPackage = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
  helium = heliumPackage.override {flags = heliumFlags;};

  profilePreferences = import ./preferences.nix;
in {
  imports = [inputs.helium.homeModules.default];

  programs.helium = {
    enable = true;
    package = heliumPackage;
    flags = heliumFlags;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "helium.desktop";
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
    };
  };

  xdg.desktopEntries.helium = {
    name = "Helium";
    exec = "${helium}/bin/helium %U";
    icon = "helium";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  xdg.configFile = extensions.webStore.configFiles;

  home.activation.heliumProfilePreferences = import ./activation.nix {
    inherit heliumProfileDir lib pkgs profilePreferences;
  };
}
