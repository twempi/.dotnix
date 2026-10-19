{inputs, ...}: {
  flake.modules.homeManager.amane = {
    home.packages = [inputs.amane.packages.x86_64-linux.default];
  };
}
