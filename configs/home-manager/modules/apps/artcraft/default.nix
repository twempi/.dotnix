{inputs, ...}: {
  flake.modules.homeManager.artcraft = {...}: {
    imports = [inputs.artcraft.homeManagerModules.default];

    programs.artcraft = {
      enable = true;
      apps = ["photocraft" "vectorcraft"];
    };
  };
}
