{inputs, ...}: {
  flake.modules.nixos.base = {
    imports = [inputs.sops-nix.nixosModules.sops];

    i18n.defaultLocale = "en_US.UTF-8";

    time.timeZone = "America/Los_Angeles";

    nix.settings.experimental-features = ["nix-command" "flakes"];

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "25.05";

    hardware.enableRedistributableFirmware = true;
  };
}
