{config, ...}: {
  # The rest of this profile is listed in ../modules.nix.
  flake.modules.homeManager.profile-desktop = {
    imports = [config.flake.modules.homeManager.base];
  };
}
