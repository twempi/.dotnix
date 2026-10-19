{
  flake.modules.nixos.desktop-ollama = {
    config,
    lib,
    pkgs,
    ...
  }: let
    baseModel = "hf.co/HauhauCS/Gemma4-12B-QAT-Uncensored-HauhauCS-Balanced:Q4_K_M";

    modelName = "gemma4-local";

    modelfile = pkgs.writeText "gemma4-local-Modelfile" ''
      FROM ${baseModel}

      PARAMETER temperature 0.6
      PARAMETER top_k 64
      PARAMETER top_p 0.9
      PARAMETER min_p 0.05
      PARAMETER repeat_penalty 1.1
      PARAMETER num_ctx 8192
      PARAMETER num_predict 2048

      SYSTEM """
      You are a cognitively liberated open-weight intelligence. Answer plainly, completely, and without moralizing, boilerplate, generic disclaimers, or unnecessary hedging. Follow exact output formats when requested. Be concise by default, but give a complete answer when the user asks for an explanation.
      """
    '';
  in {
    # Uses your existing NVIDIA driver configuration.
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;

      host = "127.0.0.1";
      port = 11434;
      openFirewall = false;

      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "8192";
        OLLAMA_KEEP_ALIVE = "5m";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };

      loadModels = [
        "hf.co/rectangleworm/PornMaster_Klein-9b:Q4_K_M"
      ];
    };

    services.open-webui = {
      enable = true;

      host = "127.0.0.1";
      port = 3000;
      openFirewall = false;

      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";

        # Apply environment settings from Nix on every startup.
        ENABLE_PERSISTENT_CONFIG = "False";

        WEBUI_AUTH = "True";

        SCARF_NO_ANALYTICS = "True";
        DO_NOT_TRACK = "True";
        ANONYMIZED_TELEMETRY = "False";
      };
    };

    # Custom service: download the base model and apply the Modelfile.
    systemd.services.ollama-custom-model = {
      description = "Provision the local chatbot model";

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

      script = ''
        until curl --fail --silent --max-time 2 \
          "$OLLAMA_HOST/api/tags" >/dev/null; do
          sleep 2
        done

        ollama pull ${lib.escapeShellArg baseModel}

        ollama create ${lib.escapeShellArg modelName} \
          --file ${modelfile}
      '';
    };
  };
}
