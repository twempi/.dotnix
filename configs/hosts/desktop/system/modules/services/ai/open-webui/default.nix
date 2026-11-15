{
  flake.modules.nixos.desktop-open-webui = {
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
  };
}
