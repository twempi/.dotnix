{inputs, ...}: {
  # Imports the upstream module itself instead of homeManager.hermes-agent, which
  # also installs the desktop app.
  flake.modules.homeManager.t480s-hermes-agent = {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    programs.hermes-agent.enable = true;

    services.hermes-agent = {
      enable = true;
      gateway.enable = true;

      # Written by sops from the t480s-hermes-agent NixOS module: NTFY_TOKEN and
      # the CALENDAR_*_ICS feed URLs.
      environmentFiles = ["/run/secrets/hermes_env"];

      environment = {
        # File tools may read the synced notes but only write Hermes' own state.
        HERMES_WRITE_SAFE_ROOT = "/home/edward/.hermes";

        NTFY_SERVER_URL = "http://127.0.0.1:2586";
        NTFY_TOPIC = "hermes";
        NTFY_ALLOWED_USERS = "hermes";
        NTFY_HOME_CHANNEL = "hermes";
        NTFY_MARKDOWN = "true";
      };

      settings = {
        model = {
          default = "gpt-6.1-sol";
          provider = "openai-codex";
          base_url = "https://chatgpt.com/backend-api/codex";
        };

        timezone = "America/Los_Angeles";

        approvals.mode = "manual";

        terminal.env_passthrough = ["CALENDAR_PERSONAL_ICS" "CALENDAR_SCHOOL_ICS"];
      };
    };
  };
}
