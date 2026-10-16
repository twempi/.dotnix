{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  startpageOrigin = "https://t480s.tailae03d0.ts.net";
  heliumProfileDir = "Profile";
  startpageDir = "${config.xdg.stateHome}/helium/startpage-extension";

  extensions = import ./extensions {
    inherit config inputs lib pkgs startpageDir startpageOrigin;
  };

  heliumFlags = [
    "--profile-directory=${heliumProfileDir}"
    "--force-dark-mode"
    "--load-extension=${lib.concatStringsSep "," (map toString extensions.unpackedPaths)}"
  ];

  heliumPackage = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
  helium = heliumPackage.override {flags = heliumFlags;};

  # Theme colour lives in user prefs (not the Chromium policy) so each
  # theme-switcher specialisation can set it. Chromium stores the opaque
  # SkColor as a signed 32-bit int, hence the offset.
  themePreferencesFile = "${config.xdg.configHome}/helium/theme-preferences.json";
  themePreferences = {
    browser.theme = {
      user_color2 = lib.fromHexString config.lib.stylix.colors.base00 - 16777216;
      is_grayscale2 = false;
    };
    extensions.theme.id = "user_color_theme_id";
  };

  profilePreferences = import ./preferences.nix;

  # Helium reads Preferences only at startup and rewrites them on exit, so the
  # theme is merged in just before a fresh start rather than at activation.
  heliumLauncher = pkgs.writeShellApplication {
    name = "helium";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.procps];
    text = ''
      prefs_file="$HOME/.config/net.imput.helium/${heliumProfileDir}/Preferences"
      theme_file="${themePreferencesFile}"

      if [[ -f "$prefs_file" && -f "$theme_file" ]] && ! pgrep -f '/opt/helium/helium( |$)' >/dev/null; then
        if merged=$(jq -s '.[0] * .[1]' "$prefs_file" "$theme_file"); then
          printf '%s\n' "$merged" >"$prefs_file.tmp"
          mv "$prefs_file.tmp" "$prefs_file"
        fi
      fi

      exec ${helium}/bin/helium "$@"
    '';
  };
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

  # Takes priority over the programs.helium binary so every launch applies the theme.
  home.packages = [(lib.hiPrio heliumLauncher)];

  xdg.desktopEntries.helium = {
    name = "Helium";
    exec = "${heliumLauncher}/bin/helium %U";
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

  xdg.configFile =
    extensions.webStore.configFiles
    // {
      "helium/theme-preferences.json".text = builtins.toJSON themePreferences;
    };

  home.activation.heliumProfilePreferences = import ./activation.nix {
    inherit heliumProfileDir lib pkgs profilePreferences;
  };

  # Real files, not a symlink: Chromium resolves symlinked extension paths at
  # load time and rejects resources that resolve outside the extension root.
  home.activation.heliumStartpage = lib.hm.dag.entryAfter ["writeBoundary"] ''
    startpage_dir=${lib.escapeShellArg startpageDir}

    run mkdir -p "$(dirname "$startpage_dir")"
    run rm -rf "$startpage_dir.new"
    run cp -rL --no-preserve=mode,ownership ${extensions.customStartpage} "$startpage_dir.new"
    run rm -rf "$startpage_dir"
    run mv "$startpage_dir.new" "$startpage_dir"
  '';
}
