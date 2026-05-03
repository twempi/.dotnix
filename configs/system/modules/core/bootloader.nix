{pkgs, ...}: let
  mac-style-src = pkgs.fetchFromGitHub {
    owner = "SergioRibera";
    repo = "s4rchiso-plymouth-theme";
    rev = "2f782f4b68ce1c00cef3fde6970d7b4241bb97d4";
    sha256 = "sha256-bjtQvzupAFX5AYAIyBXSFgWhaG4nP4TvgKDoKyUhZ4U=";
  };
  mac-style-load = pkgs.callPackage "${mac-style-src}/package.nix" {};
in {
  stylix.targets.grub = {
    enable = true;
  };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        devices = ["nodev"];
        efiSupport = true;
        useOSProber = true;
      };
      timeout = 5;
    };

    plymouth = {
      enable = true;
      theme = "mac-style";
      themePackages = [mac-style-load];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };
}
