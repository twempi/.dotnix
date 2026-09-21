{
  config,
  inputs,
  lib,
  pkgs,
  hostname,
  ...
}: let
  learningFolder = "/home/edward/Documents/notes/200 Knowledge/Learning/Courses";
in {
  imports = [
    inputs.pi.homeModules.default
  ];

  programs.pi.coding-agent = {
    enable = true;

    jail = {
      # Keep Pi isolated from the rest of the home directory by default.
      enable = true;

      permissions = combinators:
        with combinators;
          [
            network
            (add-pkg-deps [
              # Provides pdftotext and pdfinfo for the course PDFs.
              pkgs.poppler-utils
            ])
          ]
          ++ lib.optionals (hostname == "desktop") [
            (readwrite learningFolder)
          ]
          ++ lib.optionals (hostname != "desktop") [
            mount-cwd
          ];
    };
  };

  # Starts the desktop Pi instance in the only directory exposed to its jail.
  home.packages = lib.optionals (hostname == "desktop") [
    (pkgs.writeShellApplication {
      name = "pi-learn";
      runtimeInputs = [config.programs.pi.coding-agent.finalPackage];
      text = ''
        cd ${lib.escapeShellArg learningFolder}
        exec pi "$@"
      '';
    })
  ];
}
