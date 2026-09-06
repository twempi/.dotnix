{pkgs, ...}: let
  t3codePackage = pkgs.t3code.override {
    enableGit = false;
    enableGitHub = false;
  };
in {
  programs.t3code = {
    enable = true;
    package = t3codePackage;

    userSettings = {
      textGenerationModelSelection = {
        instanceId = "codex";
        model = "gpt-5.5";
        options = [
          {
            id = "reasoningEffort";
            value = "xhigh";
          }
        ];
      };

      providerInstances = {
        cursor = {
          driver = "cursor";
          enabled = false;
          config = {
            binaryPath = "agent";
          };
        };

        claudeAgent = {
          driver = "claudeAgent";
          enabled = false;
        };

        opencode = {
          driver = "opencode";
          enabled = false;
        };
      };
    };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "t3code" ''
      exec ${t3codePackage}/bin/t3code-desktop "$@"
    '')
  ];
}
