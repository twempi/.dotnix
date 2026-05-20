{pkgs}: let
  mkUpdaterApp = {
    name,
    script,
  }: let
    package = pkgs.writeShellApplication {
      name = "update-${name}";
      runtimeInputs = with pkgs; [
        curl
        git
        jq
        nix
        perl
      ];
      text = ''
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [[ -z "$repo_root" ]]; then
          echo "error: run this from inside the dotnix git repository" >&2
          exit 1
        fi

        script="$repo_root/${script}"
        if [[ ! -f "$script" ]]; then
          echo "error: updater script not found: $script" >&2
          exit 1
        fi

        exec "$script" "$@"
      '';
    };
  in {
    type = "app";
    program = "${package}/bin/update-${name}";
  };

  iloader = pkgs.callPackage ./iloader {};
  handy = pkgs.callPackage ./handy {};
in {
  packages = rec {
    inherit iloader handy;
    default = iloader;
  };

  apps = {
    update-iloader = mkUpdaterApp {
      name = "iloader";
      script = "configs/system/pkgs/iloader/update.sh";
    };

    update-handy = mkUpdaterApp {
      name = "handy";
      script = "configs/system/pkgs/handy/update.sh";
    };
  };
}
