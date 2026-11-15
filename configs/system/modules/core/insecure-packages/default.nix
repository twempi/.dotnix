{
  flake.modules.nixos.insecure-packages = {
    nixpkgs.config.permittedInsecurePackages = [
      "electron-40.10.5"
    ];
  };
}
