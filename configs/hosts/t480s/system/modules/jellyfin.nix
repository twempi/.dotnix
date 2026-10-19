{
  flake.modules.nixos.t480s-jellyfin = {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };
}
