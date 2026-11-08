{inputs, ...}: {
  flake.modules.nixos.t480s-kalshi-trader = {pkgs, ...}: let
    kalshiTraderPort = 8787;
  in {
    imports = [inputs.twempi.nixosModules.kalshi-trader];

    services.kalshi-trader = {
      enable = true;
      port = kalshiTraderPort;
      environmentFile = "/etc/kalshi-trader.env";
    };

    systemd.services.tailscale-serve-kalshi-trader = import ./_tailscale-serve-service.nix {
      inherit pkgs;
      name = "kalshi-trader";
      description = "Expose kalshi-trader as a Tailscale Service";
      port = kalshiTraderPort;
    };
  };
}
