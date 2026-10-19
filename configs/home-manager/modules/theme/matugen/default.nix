{
  flake.modules.homeManager.matugen = {
    config,
    lib,
    ...
  }: {
    xdg.configFile."matugen" = {
      source = ./matugen;
      recursive = true;
    };
  };
}
