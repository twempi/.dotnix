{
  flake.modules.homeManager.t480s-hermes-agent = {
    pkgs,
    lib,
    ...
  }: {
    # The shared settings, SOUL.md and the Hindsight plugin come from the hermes-agent module.
    programs.hermes-agent.desktop.enable = false;

    home.packages = [pkgs.python3];

    services.hermes-agent = {
      gateway.enable = true;

      # Written by sops from the t480s-hermes-agent NixOS module: DISCORD_BOT_TOKEN,
      # DISCORD_HOME_CHANNEL, DISCORD_ALLOWED_USERS, the CALENDAR_*_ICS feed URLs and
      # EBAY_CLIENT_ID/EBAY_CLIENT_SECRET (production App ID and Cert ID) for deals.py.
      environmentFiles = ["/run/secrets/hermes_env"];

      # Browser automation uses a system Chromium on PATH; Hermes's packaged one is not on Nix.
      extraPackages = [pkgs.chromium];

      environment = {
        # File tools may read the synced notes but only write Hermes' own state and the shared skills.
        HERMES_WRITE_SAFE_ROOT = lib.concatStringsSep ":" [
          "/home/edward/.hermes"
          "/home/edward/Documents/hermes-skills"
          # The morning and weekly jobs add and tick tasks here (see jobs.nix).
          "/home/edward/Documents/notes/300 Personal/Daily"
          "/home/edward/Documents/notes/300 Personal/Weekly"
          "/home/edward/Documents/notes/100 School/School To Do's.md"
        ];
      };

      settings = {
        # The gateway and cron jobs are light work, so a cheap model.
        model = {
          default = "gpt-6-luna";
          provider = "openai-codex";
          base_url = "https://chatgpt.com/backend-api/codex";
        };

        # Hermes scrubs secrets from the terminal and cron scripts unless they are listed here.
        terminal.env_passthrough = ["CALENDAR_PERSONAL_ICS" "CALENDAR_SCHOOL_ICS" "EBAY_CLIENT_ID" "EBAY_CLIENT_SECRET"];
      };

      # The server runs on this host; its Tailscale Service address is for the other machines.
      hermesHomeFiles."hindsight/config.json" = builtins.toJSON {
        mode = "local_external";
        api_url = "http://127.0.0.1:8888";
        bank_id = "hermes";
      };

      # Pre-run script for the local-deals job: prints only listings not seen before.
      # Facebook is searched logged out, so no account or cookie is needed.
      hermesHomeFiles."scripts/deals.py" = ./deals.py;
    };
  };
}
