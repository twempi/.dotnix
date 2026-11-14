{
  flake.modules.nixos.desktop-ollama = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # Uses your existing NVIDIA driver configuration.
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;

      host = "127.0.0.1";
      port = 11434;
      openFirewall = false;

      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "32768";
        OLLAMA_KEEP_ALIVE = "5m";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };
    };

    # Custom service: download the base models and apply the Modelfiles.
    # Each file in models/ appends its own pull and create commands.
    systemd.services.ollama-custom-model = {
      description = "Provision the local chatbot models";

      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      requires = ["ollama.service"];

      after = [
        "network-online.target"
        "ollama.service"
      ];

      path = [
        config.services.ollama.package
        pkgs.curl
      ];

      environment = {
        OLLAMA_HOST = "http://127.0.0.1:11434";
        HOME = "/var/lib/ollama-custom-model";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        DynamicUser = true;
        StateDirectory = "ollama-custom-model";

        TimeoutStartSec = "infinity";
        Restart = "on-failure";
        RestartSec = "15s";
      };

      script = lib.mkBefore ''
        until curl --fail --silent --max-time 2 \
          "$OLLAMA_HOST/api/tags" >/dev/null; do
          sleep 2
        done
      '';
    };
  };
}
