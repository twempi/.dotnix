{inputs, ...}: {
  flake.modules.nixos.desktop-comfyui = {
    # This import supplies the options below and disables the nixpkgs module
    # with the same service name. Import this file through NixOS, not Home Manager.
    imports = [inputs.comfyui-nix.nixosModules.default];

    services.comfyui = {
      enable = true;
      gpuSupport = "cuda";
      listenAddress = "127.0.0.1";
      port = 8188;
      dataDir = "/var/lib/comfyui";
      openFirewall = false;

      # Includes the flake's pinned ComfyUI-GGUF custom node and dependencies.
      bundledCustomNodes = true;
      # Custom nodes come from the flake; no runtime installation is needed.
      enableManager = false;
    };
  };
}
