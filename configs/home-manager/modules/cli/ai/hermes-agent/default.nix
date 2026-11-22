{inputs, ...}: {
  flake.modules.homeManager.hermes-agent = {
    config,
    lib,
    pkgs,
    ...
  }: let
    reaPlugins = pkgs.fetchFromGitHub {
      owner = "NousResearch";
      repo = "hermes-official-plugins";
      rev = "1690b63a4790cb821fb6a319ba524815d4e09411";
      hash = "sha256-F9Q0ltt5lwH/L6+boUYn1VTbeyiPhSG8viWfPmXZUO4=";
    };
    memoryWikiPlugins = pkgs.fetchFromGitHub {
      owner = "NousResearch";
      repo = "hermes-official-plugins";
      rev = "e7a218f26db88426ab3e7376f0e000b6e356f5e7";
      hash = "sha256-zDjiWUVmWUPAyasy74mUuh+d/dpBi1SBh7GZvuTjxcI=";
    };
    # The Hermes plugin and its HTTP client; keep in step with the t480s-hindsight server image.
    hindsightSrc = pkgs.fetchFromGitHub {
      owner = "vectorize-io";
      repo = "hindsight";
      rev = "62a03bfc96f175e9ac155acc72f292bed9ac4449";
      hash = "sha256-CeRQaIr3tRQ7HXbkwuKBCZ7MPa/t4zIjAkcb+oMA8fg=";
    };
    hermesPython = config.services.hermes-agent.package.python;
    hindsightClient = hermesPython.pkgs.buildPythonPackage {
      pname = "hindsight-client";
      version = "1.2.3";
      pyproject = true;
      src = "${hindsightSrc}/hindsight-clients/python";
      build-system = [hermesPython.pkgs.hatchling];
      # Its dependencies (aiohttp, pydantic, ...) are already in Hermes' sealed venv;
      # propagating nixpkgs copies would fail the module's package collision check.
      dontCheckRuntimeDeps = true;
    };
  in {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    programs.hermes-agent = {
      enable = true;
      desktop = {
        enable = lib.mkDefault true;
      };
    };

    # No gateway or backend here: this only writes config.yaml, SOUL.md and the
    # Hindsight config into ~/.hermes. Hosts that run a gateway enable it themselves.
    services.hermes-agent = {
      enable = true;

      extraPythonPackages = [hindsightClient];

      # No model here: on desktop and g14 it is picked per task with /model or `hermes model`,
      # which writes config.yaml, and keys left undeclared survive activation.
      settings = {
        timezone = "America/Los_Angeles";

        approvals.mode = "smart";

        agent.reasoning_effort = "medium";

        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
          write_approval = false;
          # One shared memory bank on t480s (t480s-hindsight), used by every machine.
          provider = "hindsight";
        };

        # Synced between machines by the hermes-skills Syncthing folder.
        skills.create_dir = "${config.home.homeDirectory}/Documents/hermes-skills";

        # OpenAI Native search cannot read pages. Firecrawl is the documented
        # default extractor and works without a key when selected.
        web.extract_backend = "firecrawl";
      };

      # Hermes reads SOUL.md from HERMES_HOME. Replaced on every activation.
      hermesHomeFiles."SOUL.md" = ./SOUL.md;

      hermesHomeFiles."hindsight/config.json" = lib.mkDefault (builtins.toJSON {
        mode = "local_external";
        api_url = "https://hindsight.tailae03d0.ts.net:8888";
        bank_id = "hermes";
      });
    };

    home.file = {
      ".hermes/plugins/rea".source = "${reaPlugins}/rea";
      ".hermes/plugins/memory-wiki".source = "${memoryWikiPlugins}/memory-wiki";
      # Memory providers are found by directory name, so this is not an extraPlugins entry
      # (those are linked as nix-managed-<name>).
      ".hermes/plugins/hindsight".source = "${hindsightSrc}/hindsight-integrations/hermes";
    };
  };
}
