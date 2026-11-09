{inputs, ...}: {
  flake.modules.homeManager.librewolf = {
    config,
    lib,
    pkgs,
    ...
  }: let
    extensionsDir = "${config.xdg.stateHome}/librewolf/extensions";
    colors = config.lib.stylix.colors.withHashtag;
    mkXpi = import ./_mk-xpi.nix {inherit lib pkgs;};

    themedXpis = lib.mapAttrs (id: args: mkXpi (args // {inherit id;})) {
      "startpage@local" = {
        src = import ../helium/_extensions/custom-startpage.nix {
          inherit config inputs pkgs;
          startpageOrigin = "https://t480s.tailae03d0.ts.net";
        };
        manifestPatch = ''.chrome_settings_overrides.homepage = "focus/focus.html"'';
      };

      "stylix-theme@local".src = pkgs.writeTextDir "manifest.json" (builtins.toJSON {
        manifest_version = 2;
        name = "Stylix";
        version = "1.0";
        theme = {
          colors = {
            frame = colors.base00;
            tab_background_text = colors.base05;
            tab_selected = colors.base02;
            tab_text = colors.base05;
            toolbar = colors.base00;
            toolbar_text = colors.base05;
            toolbar_field = colors.base01;
            toolbar_field_text = colors.base05;
            popup = colors.base01;
            popup_text = colors.base05;
            sidebar = colors.base00;
            sidebar_text = colors.base05;
          };
          properties = {
            color_scheme = "dark";
            content_color_scheme = "dark";
          };
        };
      });
    };

    # A policy install skips an unchanged version and cancels a lower one, and
    # Firefox only enables a theme through a policy install, so activation gives
    # the themed builds an ever-increasing version to make theme switches reach
    # the browser.
    stampXpi = pkgs.writeShellApplication {
      name = "librewolf-stamp-xpi";
      runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.unzip pkgs.zip];
      text = ''
        source_xpi="$1"
        target="$2"
        work=$(mktemp -d)
        trap 'rm -rf "$work"' EXIT

        unzip -q "$source_xpi" manifest.json -d "$work"
        # Offset keeps the component within Firefox's nine digits.
        jq --arg build "$(($(date +%s) - 1700000000))" '.version += ".\($build)"' \
          "$work/manifest.json" > "$work/manifest.new"
        mv "$work/manifest.new" "$work/manifest.json"

        install -m 0644 "$source_xpi" "$target.tmp"
        (cd "$work" && zip -qj "$target.tmp" manifest.json)
        mv "$target.tmp" "$target"
      '';
    };
  in {
    # The theme extension follows Helium's colours; Stylix's target would need
    # a Firefox Color profile on top of it.
    stylix.targets.librewolf.enable = false;

    programs.librewolf.policies.ExtensionSettings =
      lib.mapAttrs (id: _: {
        install_url = "file://${extensionsDir}/${id}.xpi";
        installation_mode = "force_installed";
      })
      themedXpis;

    home.activation.librewolfThemedExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p ${lib.escapeShellArg extensionsDir}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (id: xpi: "run ${lib.getExe stampXpi} ${xpi} ${lib.escapeShellArg "${extensionsDir}/${id}.xpi"}") themedXpis)}
    '';
  };
}
