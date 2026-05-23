{
  config,
  lib,
  pkgs,
  ...
}: let
  notesDir = "${config.home.homeDirectory}/Documents/notes";

  stylixMinimalCss = import ./stylix-minimal.nix {
    inherit config pkgs;
  };
in {
  home.activation.obsidianStylixMinimalCss = lib.hm.dag.entryAfter ["writeBoundary"] ''
    obsidian_dir=${lib.escapeShellArg "${notesDir}/.obsidian"}
    snippets_dir="$obsidian_dir/snippets"

    verboseEcho "Installing Obsidian Stylix Minimal CSS snippet"

    run mkdir -p "$snippets_dir"

    run install -m644 ${lib.escapeShellArg "${stylixMinimalCss}"} \
      "$snippets_dir/stylix-minimal.css"
  '';

  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    exec = "${pkgs.obsidian}/bin/obsidian %U";
    icon = "obsidian";
    terminal = false;
    categories = ["Office"];
    mimeType = ["x-scheme-handler/obsidian"];
  };
}
