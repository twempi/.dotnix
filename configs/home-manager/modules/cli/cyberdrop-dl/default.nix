{pkgs, ...}: let
  cyberdrop-dl = pkgs.writeShellApplication {
    name = "cyberdrop-dl";

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
          pkgs.openssl
          pkgs.curl
        ]
      }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      exec uvx \
        --from cyberdrop-dl-patched \
        cyberdrop-dl-patched "$@"
    '';
  };
in {
  home.packages = [
    cyberdrop-dl
  ];
}
