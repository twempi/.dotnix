{inputs, ...}: {
  flake.modules.homeManager.agent-reach = {pkgs, ...}: let
    # Upstream is Python-only and its PyPI name is a different project, so run
    # the pinned source input through uv. Do not run `agent-reach setup`: it
    # writes its own skill into ~/.claude and ~/.codex, which Home Manager owns.
    agent-reach = pkgs.writeShellApplication {
      name = "agent-reach";

      runtimeInputs = [
        pkgs.uv
        pkgs.python312
      ];

      text = ''
        export UV_NO_MANAGED_PYTHON=1
        export UV_PYTHON="${pkgs.python312}/bin/python3"

        export LD_LIBRARY_PATH="${
          pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
          ]
        }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

        exec uvx --from ${inputs.agent-reach-src} agent-reach "$@"
      '';
    };

    skill = inputs.agent-reach-src + "/agent_reach/skill";
  in {
    home.packages = [agent-reach];

    programs.claude-code.skills.agent-reach = skill;
    programs.codex.skills.agent-reach = skill;
  };
}
