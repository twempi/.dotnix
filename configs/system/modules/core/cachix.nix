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

  cachixDaemon = pkgs.writeShellApplication {
    name = "cachix-daemon";

    runtimeInputs = [
      pkgs.cachix
      pkgs.coreutils
    ];

    text = ''
      token_file="${tokenPath}"

      if [ ! -s "$token_file" ]; then
        echo "Missing Cachix token secret at $token_file" >&2
        echo "Create secrets/cachix.yaml with cachix_twempi_token encrypted by sops-nix." >&2
        exit 1
      fi

      export CACHIX_AUTH_TOKEN
      CACHIX_AUTH_TOKEN="$(tr -d '\n' < "$token_file")"

      exec cachix daemon run \
        --no-remote-stop \
        --socket /run/cachix-daemon/socket \
        --omit-deriver \
        "${cacheName}"
    '';
  };

  cachixPostBuildHook = pkgs.writeShellApplication {
    name = "cachix-post-build-hook";

    runtimeInputs = [
      pkgs.cachix
      pkgs.coreutils
    ];

    text = ''
      set +e

      socket="/run/cachix-daemon/socket"
      out_paths="''${OUT_PATHS:-}"
      drv_path="''${DRV_PATH:-unknown derivation}"

      if [ -z "$out_paths" ]; then
        exit 0
      fi

      if [ ! -S "$socket" ]; then
        echo "Cachix daemon socket missing at $socket; skipping upload for $drv_path" >&2
        exit 0
      fi

      # OUT_PATHS is a space-separated list of Nix store paths.
      # shellcheck disable=SC2086
      cachix daemon push --socket "$socket" $out_paths
      status="$?"

      if [ "$status" -ne 0 ]; then
        echo "Cachix daemon push failed with status $status for $drv_path" >&2
      fi

      exit 0
    '';
  };
in {
  environment.systemPackages = with pkgs; [
    cachix
    sops
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

  systemd.services.cachix-daemon = {
    description = "Upload locally built Nix store paths to Cachix";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    environment.HOME = "/var/lib/cachix-daemon";
    restartTriggers = lib.optional hasCachixSecret secretFile;

    unitConfig.ConditionPathExists = tokenPath;

    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe cachixDaemon;
      Restart = "always";
      RestartSec = "10s";
      RuntimeDirectory = "cachix-daemon";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "cachix-daemon";
    };
  };

  nix.settings = {
    post-build-hook = lib.getExe cachixPostBuildHook;

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
