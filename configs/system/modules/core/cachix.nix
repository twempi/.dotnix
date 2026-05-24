{
  config,
  lib,
  pkgs,
  ...
}: let
  cacheName = "twempi";
  cacheUrl = "https://${cacheName}.cachix.org";
  cachePublicKey = "twempi.cachix.org-1:pF58M/DIEWsxFOeP6mXqRPxzHxcymwqvxrIcBSQU7Ik=";

  secretFile = ../../../../secrets/cachix.yaml;
  hasCachixSecret = builtins.pathExists secretFile;
  tokenPath =
    if hasCachixSecret
    then config.sops.secrets.cachix_twempi_token.path
    else "/run/secrets/cachix_twempi_token";

  cachixPushCurrentSystem = pkgs.writeShellApplication {
    name = "cachix-push-current-system";

    runtimeInputs = [
      pkgs.cachix
      pkgs.coreutils
      pkgs.nix
    ];

    text = ''
      cache="${cacheName}"
      token_file="${tokenPath}"
      state_dir="/var/lib/cachix-system-push"
      last_file="$state_dir/${cacheName}-last-system"

      if [ ! -s "$token_file" ]; then
        echo "Missing Cachix token secret at $token_file" >&2
        echo "Create secrets/cachix.yaml with cachix_twempi_token encrypted by sops-nix." >&2
        exit 1
      fi

      system_path="$(readlink -f /run/current-system)"

      mkdir -p "$state_dir"

      if [ -f "$last_file" ] && [ "$(cat "$last_file")" = "$system_path" ]; then
        echo "Current system path already pushed to Cachix: $system_path"
        exit 0
      fi

      export CACHIX_AUTH_TOKEN
      CACHIX_AUTH_TOKEN="$(tr -d '\n' < "$token_file")"

      echo "Pushing current system closure to Cachix cache: $cache"
      nix path-info -r "$system_path" | cachix push "$cache"

      printf '%s\n' "$system_path" > "$last_file"
    '';
  };
in {
  environment.systemPackages = with pkgs; [
    cachix
    sops
    cachixPushCurrentSystem
  ];

  sops = lib.mkIf hasCachixSecret {
    defaultSopsFile = secretFile;

    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    secrets.cachix_twempi_token = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  systemd.services.cachix-push-current-system = {
    description = "Push the current NixOS system closure to Cachix";
    wants = ["network-online.target"];
    after = ["network-online.target"];

    unitConfig.ConditionPathExists = tokenPath;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe cachixPushCurrentSystem;
      StateDirectory = "cachix-system-push";
      Restart = "on-failure";
      RestartSec = "2min";
    };
  };

  systemd.paths.cachix-push-current-system = {
    description = "Push the current NixOS system closure to Cachix after rebuilds";
    wantedBy = ["multi-user.target"];

    pathConfig = {
      PathChanged = "/nix/var/nix/profiles/system";
      Unit = "cachix-push-current-system.service";
    };
  };

  nix.settings = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      cacheUrl
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      cachePublicKey
    ];

    trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      cacheUrl
    ];
  };
}
