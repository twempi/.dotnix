{
  nixpkgs.overlays = [
    (final: prev: {
      t3code = prev.t3code.override {
        t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.patchelf];
          postFixup =
            (old.postFixup or "")
            + ''
              for f in $(find $out -type f -path '*node-pty*/prebuilds/linux-x64/pty.node'); do
                patchelf --add-rpath ${final.lib.makeLibraryPath [final.stdenv.cc.cc.lib]} "$f"
              done
            '';
        });
        # reuse the existing resource monitor so it doesn't get rebuilt
        t3code-resource-monitor = prev.t3code.resourceMonitor;
      };
    })
  ];
  programs.t3code = {
    enable = true;

    userSettings.providerInstances = {
      codex = {
        driver = "codex";
        enabled = true;
        config.binaryPath = "/home/edward/.nix-profile/bin/codex";
      };
      claudeAgent = {
        driver = "claudeAgent";
        enabled = true;
        config.binaryPath = "/home/edward/.nix-profile/bin/claude";
      };
    };
  };
}
