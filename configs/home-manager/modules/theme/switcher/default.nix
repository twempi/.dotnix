{inputs, ...}: {
  flake.modules.homeManager.switcher = {
    config,
    hostname,
    lib,
    pkgs,
    ...
  }: let
    # Each scheme is prebuilt as a Home Manager specialisation, so switching
    # between them at runtime is an activation instead of a rebuild.
    schemes = [
      "rose-pine"
      "everforest-dark-medium"
      "catppuccin-mocha"
      "gruvbox-material-dark-medium"
      "tokyo-night-moon"
      "ocean"
      "black-metal-dark-funeral"
      "grayscale-dark"
      "ayu-mirage"
      "charcoal-light"
      "nord"
      "porple"
      "serendipity-sunset"
    ];

    stateDir = "${config.xdg.stateHome}/theme-switcher";

    themeSwitch = pkgs.writeShellApplication {
      name = "theme-switch";
      runtimeInputs = [pkgs.coreutils pkgs.libnotify pkgs.procps pkgs.util-linux];
      text =
        ''
          state_dir="${stateDir}"
          sway_reload="${../../desktop/windowmanagers/sway/reload.sh}"
        ''
        + builtins.readFile ./theme-switch.sh;
    };
  in {
    specialisation = lib.genAttrs schemes (scheme: {
      # Otherwise every scheme re-imports nixpkgs, about 9 GB across all of them.
      configuration._module.args.pkgs = lib.mkForce pkgs;
      configuration.stylix.base16Scheme = lib.mkForce (inputs.tt-schemes + "/base16/${scheme}.yaml");
    });

    home.packages = [themeSwitch];

    programs.fish.shellAliases.hms = "home-manager switch --flake ~/.dotnix#edward-${hostname} && theme-switch --restore";

    # Activating a specialisation creates a generation without the
    # specialisation directory, so keep a GC-rooted link to the last base one.
    home.activation.themeSwitcherBase = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [[ -d "$newGenPath/specialisation" ]]; then
        run mkdir -p ${lib.escapeShellArg stateDir}
        run --silence nix-store --realise "$newGenPath" --add-root ${lib.escapeShellArg "${stateDir}/base"}
      fi
    '';
  };
}
