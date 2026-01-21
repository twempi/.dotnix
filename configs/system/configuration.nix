{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./modules.nix
  ];
  i18n.defaultLocale = "en_US.UTF-8";

  time = {
    timeZone = "America/Los_Angeles";
    hardwareClockInLocalTime = true;
  };

  services.displayManager.ly.enable = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
