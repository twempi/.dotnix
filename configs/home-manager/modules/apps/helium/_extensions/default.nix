{
  config,
  inputs,
  lib,
  pkgs,
  startpageDir,
  startpageOrigin,
}: let
  customStartpage = import ./custom-startpage.nix {
    inherit config inputs pkgs startpageOrigin;
  };
  discordToVesktop = import ./discord-to-vesktop.nix {inherit pkgs;};
  webStore = import ./web-store.nix {inherit lib pkgs;};
in {
  # The startpage loads from a fixed directory that activation refreshes, so
  # theme switches reach it without changing Helium's launch flags.
  unpackedPaths = [
    startpageDir
    discordToVesktop
  ];

  inherit customStartpage webStore;
}
