{
  flake.modules.homeManager.dev = {pkgs, ...}: let
    pipxNoCheck = pkgs.pipx.overridePythonAttrs (_: {
      doCheck = false;
    });
  in {
    home.packages = [
      pipxNoCheck
      (pkgs.python313.withPackages (ps: [
        ps.pywal
        ps.watchdog
      ]))
    ];
  };
}
