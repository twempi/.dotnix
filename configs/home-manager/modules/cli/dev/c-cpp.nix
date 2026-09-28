{
  lib,
  pkgs,
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
in {
  home.packages = [
    pkgs.gcc
    clangTools
    pkgs.cmake
    pkgs.gnumake
    pkgs.ninja
    pkgs.gdb
    pkgs.pkg-config
  ];
}
