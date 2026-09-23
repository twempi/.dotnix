{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homePageOrigin = "https://t480s.tailae03d0.ts.net";
  homePage = "${homePageOrigin}/";
  heliumProfileDir = "Profile";

  extensions = import ./extensions {
    inherit config homePageOrigin lib pkgs;
  };

  profilePreferences = import ./preferences.nix {inherit homePage;};
in {
  imports = [inputs.helium.homeModules.helium];

  programs.helium = {
    enable = true;
    defaultBrowser = true;
    package = inputs.helium-package.packages.${pkgs.stdenv.hostPlatform.system}.helium;

    extensions = [];

    extraFlags = [
      "--profile-directory=${heliumProfileDir}"
      "--force-dark-mode"
      "--load-extension=${lib.concatStringsSep "," (map toString extensions.unpackedPaths)}"
    ];

    extraPolicies = import ./policies.nix {
      inherit homePage;
      extensionIds = extensions.webStore.extensionIds;
    };

    # The upstream HM module writes preferences to the Default profile only.
    # Since this config launches Profile, leave this empty and use the
    # activation hook below instead.
    preferences = {};
  };

  xdg.configFile = extensions.webStore.configFiles;

  home.activation.heliumProfilePreferences = import ./activation.nix {
    inherit heliumProfileDir lib pkgs profilePreferences;
  };
}
