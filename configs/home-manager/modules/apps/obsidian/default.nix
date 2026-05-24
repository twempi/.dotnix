{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.obsidian.stylixMinimal;

  stylixMinimalCss = import ./stylix-minimal.nix {
    inherit config lib pkgs;
  };
in {
  options.programs.obsidian.stylixMinimal = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the Stylix-generated Minimal CSS snippet without managing Obsidian appearance settings.";
    };

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documents/notes";
      description = "Absolute path to the Obsidian vault that should receive the Stylix Minimal CSS snippet.";
    };
  };

  config = {
    home.activation.obsidianStylixMinimalCss = lib.mkIf cfg.enable (lib.hm.dag.entryAfter ["writeBoundary"] ''
      obsidian_dir=${lib.escapeShellArg "${cfg.vaultPath}/.obsidian"}
      snippets_dir="$obsidian_dir/snippets"

      verboseEcho "Installing Obsidian Stylix Minimal CSS snippet"

      run mkdir -p "$snippets_dir"

      run install -m644 ${lib.escapeShellArg "${stylixMinimalCss}"} \
        "$snippets_dir/stylix-minimal.css"
    '');

    xdg.desktopEntries.obsidian = {
      name = "Obsidian";
      exec = "${pkgs.obsidian}/bin/obsidian %U";
      icon = "obsidian";
      terminal = false;
      categories = ["Office"];
      mimeType = ["x-scheme-handler/obsidian"];
    };
  };
}
