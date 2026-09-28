{
  pkgs,
  pkgsStable,
  ...
}: let
  pythonStable = pkgs.writeShellApplication {
    name = "python3-stable";
    text = ''
      exec ${pkgsStable.python3}/bin/python3 "$@"
    '';
  };

  pipxStable = pkgsStable.pipx.overridePythonAttrs (_: {
    doCheck = false;
  });
in {
  home.packages = [
    pythonStable
    pipxStable
    (pkgs.python313.withPackages (ps: [
      ps.pywal
      ps.watchdog
    ]))
  ];
}
