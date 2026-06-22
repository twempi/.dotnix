{pkgs, ...}: let
  mkCyberdropWrapper = name:
    pkgs.writeShellApplication {
      inherit name;

      runtimeInputs = [
        pkgs.uv
        pkgs.python313
      ];

      text = ''
        export UV_NO_MANAGED_PYTHON=1
        export UV_PYTHON="${pkgs.python313}/bin/python3"

        exec uvx \
          --from cyberdrop-dl-patched \
          cyberdrop-dl-patched "$@"
      '';
    };
in {
  home.packages = [
    (mkCyberdropWrapper "cyberdrop-dl")
    (mkCyberdropWrapper "cyberdrop-dl-patched")
  ];
}
