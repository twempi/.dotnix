{
  pkgs,
  lib,
  ...
}: let
  mac-style-src = pkgs.fetchFromGitHub {
    owner = "SergioRibera";
    repo = "s4rchiso-plymouth-theme";
    rev = "2f782f4b68ce1c00cef3fde6970d7b4241bb97d4";
    sha256 = "sha256-bjtQvzupAFX5AYAIyBXSFgWhaG4nP4TvgKDoKyUhZ4U=";
  };

  mac-style-load = pkgs.callPackage "${mac-style-src}/package.nix" {};

  minimal-grub-theme-src = pkgs.fetchFromGitHub {
    owner = "aspy606";
    repo = "minimal-grub-theme";

    # Better: replace this with a full commit hash once you pin it.
    rev = "a6c4c7cdaa5590e057b09e7555eb8af8974fe94c";

    # First rebuild will fail and print the correct hash.
    # Replace lib.fakeHash with the "got:" hash from the error.
    hash = "sha256-Zu0e7s7Epy4n4aUVoAQjqshDR02PT2TH9sZRf8ureOQ=";
  };

  minimal-grub-theme = pkgs.stdenvNoCC.mkDerivation {
    pname = "minimal-grub-theme";
    version = "unstable";

    src = minimal-grub-theme-src;

    nativeBuildInputs = [pkgs.grub2];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r minimal/* $out/

      # Change 24 to whatever font size you want.
      grub-mkfont -s 24 -o $out/custom.pf2 $out/original.ttf

      runHook postInstall
    '';
  };
in {
  # Disable this, otherwise Stylix will generate/override the GRUB theme.
  stylix.targets.grub.enable = false;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        devices = ["nodev"];
        efiSupport = true;
        useOSProber = true;

        theme = minimal-grub-theme;
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
