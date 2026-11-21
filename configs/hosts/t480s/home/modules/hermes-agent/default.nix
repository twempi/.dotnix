{inputs, ...}: {
  flake.modules.homeManager.t480s-hermes-agent = {pkgs, ...}: {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    programs.hermes-agent.enable = true;

    home.packages = [pkgs.python3];

    services.hermes-agent = {
      enable = true;
      gateway.enable = true;

      # Written by sops from the t480s-hermes-agent NixOS module: DISCORD_BOT_TOKEN,
      # DISCORD_HOME_CHANNEL, DISCORD_ALLOWED_USERS and the CALENDAR_*_ICS feed URLs.
      environmentFiles = ["/run/secrets/hermes_env"];

      # Browser automation uses a system Chromium on PATH; Hermes's packaged one is not on Nix.
      extraPackages = [pkgs.chromium];

      environment = {
        # File tools may read the synced notes but only write Hermes' own state.
        HERMES_WRITE_SAFE_ROOT = "/home/edward/.hermes";
      };

      settings = {
        model = {
          default = "gpt-6.1-sol";
          provider = "openai-codex";
          base_url = "https://chatgpt.com/backend-api/codex";
        };

        timezone = "America/Los_Angeles";

        approvals.mode = "smart";

        agent.reasoning_effort = "medium";

        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
          write_approval = false;
        };

        terminal.env_passthrough = ["CALENDAR_PERSONAL_ICS" "CALENDAR_SCHOOL_ICS"];

        # OpenAI Native search cannot read pages. Firecrawl is the documented
        # default extractor and works without a key when selected.
        web.extract_backend = "firecrawl";
      };

      # Hermes reads SOUL.md from HERMES_HOME. Replaced on every activation.
      hermesHomeFiles."SOUL.md" = ./SOUL.md;

      # Pre-run script for the local-deals job: prints only listings not seen before.
      # Facebook is searched logged out, so no account or cookie is needed.
      hermesHomeFiles."scripts/deals.py" = ./deals.py;
    };
  };
}
