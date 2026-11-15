{inputs, ...}: {
  # Imports the upstream module itself instead of homeManager.hermes-agent, which
  # also installs the desktop app.
  flake.modules.homeManager.t480s-hermes-agent = {pkgs, ...}: {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    programs.hermes-agent.enable = true;

    # Hermes Desktop's SSH mode runs `python3` on this host before starting Hermes.
    home.packages = [pkgs.python3];

    services.hermes-agent = {
      enable = true;
      gateway.enable = true;

      # Written by sops from the t480s-hermes-agent NixOS module: NTFY_TOKEN and
      # the CALENDAR_*_ICS feed URLs.
      environmentFiles = ["/run/secrets/hermes_env"];

      # Browser automation uses a system Chromium on PATH; Hermes's packaged one is not on Nix.
      extraPackages = [pkgs.chromium];

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
      hermesHomeFiles."SOUL.md" = ''
        You are Hermes, Edward's personal assistant in San Luis Obispo.

        Default to concise answers: lead with the answer, skip filler, and use a short list only when it helps.

        For school questions (courses, homework, exams, notes in ~/Documents/notes or ~/Documents/school), switch to study-helper mode: explain the steps and the reasoning, not just the result, then end with one short question to check understanding. Name the note or file the material came from.
      '';

      # Replaced on every activation, so jobs created with `hermes cron create`
      # are not kept. Change jobs here and rebuild.
      hermesHomeFiles."cron/jobs.json" = builtins.toJSON {
        jobs = [
          {
            id = "morning-briefing";
            name = "Morning briefing";
            schedule = "0 7 * * *";
            timezone = "America/Los_Angeles";
            deliver = "ntfy";
            workdir = "/home/edward/Documents";
            prompt = ''
              Morning briefing for San Luis Obispo. Do these in order:
              1. Calendar: run curl -s "$CALENDAR_PERSONAL_ICS" and curl -s "$CALENDAR_SCHOOL_ICS", then list today's events with times.
              2. Weather: run curl -s "wttr.in/San+Luis+Obispo?format=j1" and give today's conditions with the high and low in F.
              3. Deadlines: search ./notes and ./school for anything due in the next 7 days.
              Keep it short, in Markdown. Do not modify any files.
            '';
          }
          {
            id = "weekly-deadlines";
            name = "Weekly deadlines";
            schedule = "0 18 * * 0";
            timezone = "America/Los_Angeles";
            deliver = "ntfy";
            workdir = "/home/edward/Documents";
            prompt = ''
              Weekly overview: list every assignment, exam and deadline due Monday through Sunday of the coming week, from curl -s "$CALENDAR_SCHOOL_ICS" and the notes in ./notes and ./school. Group by day, most urgent first. Do not modify any files.
            '';
          }
        ];
      };
    };
  };
}
