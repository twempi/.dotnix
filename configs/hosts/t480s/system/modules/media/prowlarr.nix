{
  flake.modules.nixos.t480s-prowlarr = {pkgs, ...}: let
    prowlarrPort = 9696;
  in {
    services.prowlarr.enable = true;

    # Admin UI stays off the LAN.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [prowlarrPort];

    systemd.services.tailscale-serve-prowlarr = import ../_tailscale-serve-service.nix {
      inherit pkgs;
      name = "prowlarr";
      description = "Expose Prowlarr as a Tailscale Service";
      port = prowlarrPort;
    };
  };
}
