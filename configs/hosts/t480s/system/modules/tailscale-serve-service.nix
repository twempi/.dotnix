{
  pkgs,
  name,
  description,
  port,
}: {
  inherit description;
  after = ["tailscaled.service"];
  wants = ["tailscaled.service"];
  wantedBy = ["multi-user.target"];

  restartIfChanged = true;

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    TimeoutStartSec = 30;
  };

  script = ''
    set -euo pipefail

    ${pkgs.util-linux}/bin/flock -w 120 /run/tailscale-serve.lock \
      ${pkgs.tailscale}/bin/tailscale serve --yes --bg \
        --service=svc:${name} \
        --https=${toString port} \
        http://127.0.0.1:${toString port}
  '';
}
