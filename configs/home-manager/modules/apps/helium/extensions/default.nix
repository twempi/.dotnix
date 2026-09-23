{
  config,
  homePageOrigin,
  lib,
  pkgs,
}: let
  customStartpage = import ./custom-startpage.nix {
    inherit config homePageOrigin pkgs;
  };
  discordToVesktop = import ./discord-to-vesktop.nix {inherit pkgs;};
  webStore = import ./web-store.nix {inherit lib pkgs;};
in {
  unpackedPaths = [
    customStartpage
    discordToVesktop
  ];

  inherit webStore;
}
