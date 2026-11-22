{
  # Shared long-term memory for Hermes on every machine; see the hermes-agent Home Manager module.
  flake.modules.nixos.t480s-hindsight = {pkgs, ...}: let
    hindsightPort = 8888;
  in {
    virtualisation.oci-containers.containers.hindsight = {
      # hindsight-api 1.2.3: the API without the web UI, with local embedding and reranking
      # models. Keep it in step with the plugin pinned in the hermes-agent module.
      image = "ghcr.io/vectorize-io/hindsight-api@sha256:2f318da3489f6493a5ec78f3d7019cd70835383fe4f4ffd1af9e080babd91d6c";
      ports = ["127.0.0.1:${toString hindsightPort}:8888"];
      volumes = [
        # Embedded Postgres.
        "hindsight-data:/home/hindsight/.pg0"
        # Its own Codex login: the provider refreshes and rewrites auth.json, so it must
        # not share one with the Codex CLI or Hermes.
        "/var/lib/hindsight/codex:/home/hindsight/.codex"
      ];
      environment = {
        HINDSIGHT_API_LLM_PROVIDER = "openai-codex";
        HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
        HINDSIGHT_API_LLM_CODEX_HOME = "/home/hindsight/.codex";
        HINDSIGHT_API_WORKER_ID = "t480s";
      };
      extraOptions = [
        "--shm-size=1g"
        "--stop-timeout=75"
      ];
    };

    # UID 1000 is the image's hindsight user.
    systemd.tmpfiles.rules = [
      "d /var/lib/hindsight 0755 root root -"
      "d /var/lib/hindsight/codex 0700 1000 1000 -"
    ];

    systemd.services.tailscale-serve-hindsight = import ../_tailscale-serve-service.nix {
      inherit pkgs;
      name = "hindsight";
      description = "Expose Hindsight as a Tailscale Service";
      port = hindsightPort;
    };
  };
}
