{
  lib,
  pkgs,
  pkgsStable,
  ...
}: let
  clangTools = pkgs.symlinkJoin {
    name = "clang-user-tools";
    paths = [
      pkgs.llvmPackages.clang-unwrapped
    ];
    postBuild = ''
      if [ ! -e "$out/bin/clang" ]; then
        ln -s clang-${lib.versions.major pkgs.llvmPackages.clang-unwrapped.version} "$out/bin/clang"
      fi
    '';
  };

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
    pkgs.gcc
    clangTools
    pkgs.zig
    pkgs.lua
    pythonStable
    pipxStable
    (pkgs.python313.withPackages (ps: [
      ps.pywal
      ps.watchdog
    ]))
  ];
}
