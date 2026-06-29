{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
  font = config.stylix.fonts.monospace.name;
  vesktopPackage = config.programs.nixcord.vesktop.package;
  vesktopLauncher = pkgs.writeShellScriptBin "vesktop-launch" ''
    args=()
    for arg in "$@"; do
      case "$arg" in
        %f|%F|%u|%U) ;;
        *) args+=("$arg") ;;
      esac
    done

    exec ${lib.getExe vesktopPackage} "''${args[@]}"
  '';
in {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # stylix.targets.nixcord.enable = true;
  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
    discord.vencord.enable = false;

    config = {
      frameless = true;
      autoUpdate = true;
      autoUpdateNotification = true;
      enabledThemes = ["stylix-system24.css"];
      themes."stylix-system24" = ''
        /**
         * @name stylix-system24
         * @description system24 layout with colors generated from Stylix.
         * @author refact0r, Stylix
         * @version 1.0.0
        **/

        @import url('https://refact0r.github.io/system24/build/system24.css');

        body {
            --font: '${font}';
            --code-font: '${font}';
            font-weight: 300;
            letter-spacing: -0.05ch;

            --gap: 12px;
            --divider-thickness: 4px;
            --border-thickness: 2px;
            --border-hover-transition: 0.2s ease;

            --animations: on;
            --list-item-transition: 0.2s ease;
            --dms-icon-svg-transition: 0.4s ease;

            --top-bar-height: var(--gap);
            --top-bar-button-position: titlebar;
            --top-bar-title-position: off;
            --subtle-top-bar-title: off;

            --custom-window-controls: off;
            --window-control-size: 14px;

            --custom-dms-icon: hide;
            --dms-icon-svg-url: url("");
            --dms-icon-svg-size: 90%;
            --dms-icon-color-before: var(--icon-subtle);
            --dms-icon-color-after: var(--white);
            --custom-dms-background: off;
            --dms-background-image-url: url("");
            --dms-background-image-size: cover;
            --dms-background-color: linear-gradient(70deg, var(--blue-2), var(--purple-2), var(--red-2));

            --background-image: off;
            --background-image-url: url("");

            --transparency-tweaks: off;
            --remove-bg-layer: off;
            --panel-blur: off;
            --blur-amount: 12px;
            --bg-floating: var(--bg-3);

            --small-user-panel: on;
            --unrounding: on;
            --custom-spotify-bar: on;
            --ascii-titles: on;
            --ascii-loader: system24;

            --panel-labels: on;
            --label-color: var(--text-muted);
            --label-font-weight: 500;
        }

        :root {
            --colors: on;

            --text-0: var(--bg-4);
            --text-1: ${colors.base07};
            --text-2: ${colors.base06};
            --text-3: ${colors.base05};
            --text-4: ${colors.base04};
            --text-5: ${colors.base03};

            --bg-1: ${colors.base03};
            --bg-2: ${colors.base02};
            --bg-3: ${colors.base01};
            --bg-4: ${colors.base00};
            --hover: color-mix(in srgb, ${colors.base05} 10%, transparent);
            --active: color-mix(in srgb, ${colors.base05} 20%, transparent);
            --active-2: color-mix(in srgb, ${colors.base05} 30%, transparent);
            --message-hover: color-mix(in srgb, ${colors.base05} 10%, transparent);

            --accent-1: ${colors.base0E};
            --accent-2: ${colors.base0E};
            --accent-3: ${colors.base0E};
            --accent-4: color-mix(in srgb, ${colors.base0E} 85%, ${colors.base05});
            --accent-5: color-mix(in srgb, ${colors.base0E} 70%, ${colors.base00});
            --accent-new: ${colors.base08};
            --mention: linear-gradient(to right, color-mix(in srgb, var(--accent-2) 10%, transparent) 40%, transparent);
            --mention-hover: linear-gradient(to right, color-mix(in srgb, var(--accent-2) 5%, transparent) 40%, transparent);
            --reply: linear-gradient(to right, color-mix(in srgb, var(--text-3) 10%, transparent) 40%, transparent);
            --reply-hover: linear-gradient(to right, color-mix(in srgb, var(--text-3) 5%, transparent) 40%, transparent);

            --online: ${colors.base0B};
            --dnd: ${colors.base08};
            --idle: ${colors.base0A};
            --streaming: ${colors.base0E};
            --offline: var(--text-4);

            --border-light: var(--hover);
            --border: var(--active);
            --border-hover: var(--accent-2);
            --button-border: color-mix(in srgb, ${colors.base05} 10%, transparent);

            --red-1: color-mix(in srgb, ${colors.base08} 75%, ${colors.base05});
            --red-2: ${colors.base08};
            --red-3: ${colors.base08};
            --red-4: color-mix(in srgb, ${colors.base08} 80%, ${colors.base00});
            --red-5: color-mix(in srgb, ${colors.base08} 65%, ${colors.base00});

            --green-1: color-mix(in srgb, ${colors.base0B} 75%, ${colors.base05});
            --green-2: ${colors.base0B};
            --green-3: ${colors.base0B};
            --green-4: color-mix(in srgb, ${colors.base0B} 80%, ${colors.base00});
            --green-5: color-mix(in srgb, ${colors.base0B} 65%, ${colors.base00});

            --blue-1: color-mix(in srgb, ${colors.base0D} 75%, ${colors.base05});
            --blue-2: ${colors.base0D};
            --blue-3: ${colors.base0D};
            --blue-4: color-mix(in srgb, ${colors.base0D} 80%, ${colors.base00});
            --blue-5: color-mix(in srgb, ${colors.base0D} 65%, ${colors.base00});

            --yellow-1: color-mix(in srgb, ${colors.base0A} 75%, ${colors.base05});
            --yellow-2: ${colors.base0A};
            --yellow-3: ${colors.base0A};
            --yellow-4: color-mix(in srgb, ${colors.base0A} 80%, ${colors.base00});
            --yellow-5: color-mix(in srgb, ${colors.base0A} 65%, ${colors.base00});

            --purple-1: color-mix(in srgb, ${colors.base0E} 75%, ${colors.base05});
            --purple-2: ${colors.base0E};
            --purple-3: ${colors.base0E};
            --purple-4: color-mix(in srgb, ${colors.base0E} 80%, ${colors.base00});
            --purple-5: color-mix(in srgb, ${colors.base0E} 65%, ${colors.base00});
        }
      '';

      plugins = {
        experiments.enable = true;
        callTimer.enable = true;
        fakeNitro.enable = true;
        imageZoom = {
          enable = true;
          invertScroll = true;
          size = 150.0;
        };
        keepCurrentChannel.enable = true;
        mentionAvatars.enable = true;
        noF1.enable = true;
        petpet.enable = true;
        pictureInPicture.enable = true;
        whoReacted.enable = true;
        biggerStreamPreview.enable = true;
        clearUrls.enable = true;
        fixImagesQuality.enable = true;
        fixSpotifyEmbeds = {
          enable = true;
          volume = 0.05;
        };
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        gameActivityToggle = {
          enable = true;
        };
        messageLogger.enable = true;
        openInApp.enable = true;
        showHiddenChannels.enable = true;
        silentTyping.enable = true;
        spotifyCrack = {
          enable = true;
          noSpotifyAutoPause = true;
        };
        youtubeAdblock.enable = true;
      };
    };
  };

  xdg.desktopEntries.vesktop = {
    name = "Vesktop";
    genericName = "Internet Messenger";
    exec = "${lib.getExe vesktopLauncher} %U";
    icon = "vesktop";
    categories = [
      "Network"
      "InstantMessaging"
      "Chat"
    ];
    mimeType = ["x-scheme-handler/discord"];
    settings = {
      Keywords = "discord;vencord;electron;chat";
      StartupWMClass = "Vesktop";
    };
  };
}
