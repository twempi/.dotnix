{inputs, ...}: {
  imports = [inputs.artcraft.homeManagerModules.default];

  programs.artcraft = {
    enable = true;
    apps = ["photocraft" "cadcraft" "vectorcraft"];
  };
}
