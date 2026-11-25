{inputs, ...}: {
  # The Amane shell (github:MystiaFin/amane): replaces Waybar, Rofi and SwayNC on Sway and Noctalia on
  # Hyprland, with a look of its own in each.
  flake.modules.homeManager.amane = {
    config,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    # `amane ipc call` is how keybinds and scripts reach the running shell.
    amane = inputs.amane.packages.${system}.default;
    shell = pkgs.callPackage ./_package.nix {amaneSource = inputs.amane;};

    dmenu = pkgs.writeShellApplication {
      name = "amane-dmenu";
      runtimeInputs = [amane pkgs.coreutils];
      text = builtins.readFile ./scripts/dmenu.sh;
    };

    # The calendar tab's events and reminders, from Google through the sign-in in sops, which
    # stays out of the store; see the script.
    calendar = pkgs.writers.writePython3Bin "amane-calendar" {
      flakeIgnore = ["E501"];
      # the tab runs it from the shell's service too, which has no libnotify
      makeWrapperArgs = ["--prefix" "PATH" ":" "${pkgs.libnotify}/bin"];
    } (builtins.readFile ./scripts/calendar.py);

    # The usage tab's Claude and Codex limits, from the agents' own sign-ins; see the script.
    usage = pkgs.writers.writePython3Bin "amane-usage" {
      flakeIgnore = ["E501"];
    } (builtins.readFile ./scripts/usage.py);

    # The shell's icon font, family "noctalia-tabler-icons", from the Noctalia shell it was modelled on.
    tablerIconFont = pkgs.linkFarm "noctalia-tabler-font" {
      "noctalia-tabler.ttf" = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/noctalia-dev/noctalia-shell/c1249d5db25269df5f4ad735cad39aeeb95e1ea3/lib/assets/fonts/noctalia-tabler.ttf";
        hash = "sha256-NS//wekCTlod21+/nbUy2ueTg5rjOLboI08y55Kocjw=";
      };
    };

    # Amane draws no color emoji, so its emoji picker needs the outline font. Installed for
    # everyone, that font pushed Noto Color Emoji out of foot's fallback list, so only the
    # shell sees it. The rule beats NixOS's alias of "Noto Emoji" to the color font.
    fontsConf = pkgs.writeText "amane-fonts.conf" ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="family" qual="first"><string>Noto Emoji</string></test>
          <edit name="color" mode="assign"><bool>false</bool></edit>
        </match>
        <include>/etc/fonts/fonts.conf</include>
        <dir>${pkgs.noto-fonts-monochrome-emoji}/share/fonts</dir>
        <dir>${tablerIconFont}</dir>
      </fontconfig>
    '';

    # One unit per session, so each starts and stops with its compositor. Amane checks Niri, then
    # Hyprland, then Sway, so a variable left over from another session would pick the wrong one.
    shellService = target: leftovers: {
      Unit = {
        Description = "Amane shell: bar, launcher, menus, tray and notifications";
        Requisite = [target];
        PartOf = [target];
        After = [target];
      };

      Service = {
        ExecStart = "${shell}/bin/amane-shell";
        Restart = "on-failure";
        RestartSec = 2;
        # Programs it launches go through `swaymsg exec` or `uwsm app`, so they keep the normal fonts.
        Environment = ["FONTCONFIG_FILE=${fontsConf}"];
        UnsetEnvironment = leftovers;
      };

      Install.WantedBy = [target];
    };

    sessions = ["sway-session.target" "wayland-session@hyprland.desktop.target"];
  in {
    home.packages = [
      amane
      dmenu

      # The font rofi's theme named.
      pkgs.nerd-fonts.jetbrains-mono

      calendar
      usage

      (pkgs.writeShellApplication {
        name = "amane-launcher";
        runtimeInputs = [amane];
        text = ''
          exec amane ipc call launcher
        '';
      })

      (pkgs.writeShellApplication {
        name = "amane-notifications";
        runtimeInputs = [amane];
        text = ''
          exec amane ipc call notifications
        '';
      })

      (pkgs.writeShellApplication {
        name = "amane-power";
        runtimeInputs = [amane dmenu] ++ (with pkgs; [systemd hyprlock libnotify alsa-utils coreutils bash]);
        # Only nounset, like the rofi script, so the menu's exit codes reach its case.
        bashOptions = ["nounset"];
        text = builtins.readFile ./scripts/power.sh;
      })

      (pkgs.writeShellApplication {
        name = "amane-wallpaper";
        runtimeInputs = [dmenu] ++ (with pkgs; [awww libnotify findutils coreutils bash]);
        bashOptions = ["nounset"];
        text = builtins.readFile ./scripts/wallpaper.sh;
      })

      (pkgs.writeShellApplication {
        name = "amane-emoji";
        runtimeInputs = [dmenu] ++ (with pkgs; [unicode-emoji wl-clipboard python3 coreutils]);
        text =
          ''
            export UNICODE_EMOJI_TEST="${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt"
          ''
          + builtins.readFile ./scripts/emoji.sh;
      })

      (pkgs.writeShellApplication {
        name = "amane-clipboard";
        runtimeInputs = [dmenu] ++ (with pkgs; [cliphist wl-clipboard]);
        text = ''
          choice="$(cliphist list | amane-dmenu -dmenu -i -p Clipboard)"
          menu_exit=$?

          if [ "$menu_exit" -ne 0 ] || [ -z "$choice" ]; then
            exit 0
          fi

          printf '%s\n' "$choice" | cliphist decode | wl-copy
        '';
      })
    ];

    # The stylix palette; the shell watches this file, so theme-switch recolors it live.
    xdg.configFile."amane-shell/colors".text = let
      inherit (config.lib.stylix) colors;
      slots = ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07" "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"];
    in
      builtins.concatStringsSep "" (map (slot: "${slot}=#${colors.${slot}}\n") slots);

    # The shell starts with its session, so there is no D-Bus activation file.
    systemd.user.services.amane-shell =
      shellService "sway-session.target" ["HYPRLAND_INSTANCE_SIGNATURE" "NIRI_SOCKET" "MANGO_INSTANCE_SIGNATURE"];

    # UWSM's target for the Hyprland session.
    systemd.user.services.amane-shell-hyprland =
      shellService "wayland-session@hyprland.desktop.target" ["NIRI_SOCKET"];

    # The reminders follow whichever session runs the shell.
    systemd.user.services.amane-calendar-reminders = {
      Unit.Description = "Amane shell: calendar reminders";
      Service = {
        Type = "oneshot";
        ExecStart = "${calendar}/bin/amane-calendar --remind";
      };
    };

    systemd.user.timers.amane-calendar-reminders = {
      Unit = {
        Description = "Amane shell: calendar reminders";
        PartOf = sessions;
        After = sessions;
      };
      Timer = {
        OnCalendar = "minutely";
        AccuracySec = "1s";
      };
      Install.WantedBy = sessions;
    };
  };
}
