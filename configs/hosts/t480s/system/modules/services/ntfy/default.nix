{
  flake.modules.nixos.t480s-ntfy = {
    config,
    pkgs,
    ...
  }: let
    ntfyPort = 2586;
  in {
    sops.secrets.ntfy_env.sopsFile = ../../../../../../../secrets/ntfy.yaml;

    services.ntfy-sh = {
      enable = true;

      # Holds NTFY_AUTH_USERS (bcrypt hash) and NTFY_AUTH_TOKENS.
      environmentFile = config.sops.secrets.ntfy_env.path;

      settings = {
        base-url = "https://ntfy.tailae03d0.ts.net:${toString ntfyPort}";
        listen-http = "127.0.0.1:${toString ntfyPort}";

        auth-default-access = "deny-all";
        auth-access = ["edward:hermes:rw"];

        # iOS only gets instant pushes through ntfy.sh. It receives the message ID
        # and a hash of the topic URL, never the message body.
        upstream-base-url = "https://ntfy.sh";
      };
    };

    systemd.services.tailscale-serve-ntfy = import ../_tailscale-serve-service.nix {
      inherit pkgs;
      name = "ntfy";
      description = "Expose ntfy as a Tailscale Service";
      port = ntfyPort;
    };
  };
}
