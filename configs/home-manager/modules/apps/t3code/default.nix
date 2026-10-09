{...}: {
  programs.t3code = {
    enable = true;

    userSettings.providerInstances.codex = {
      driver = "codex";
      enabled = true;
      config.binaryPath = "/home/edward/.nix-profile/bin/codex";
    };
  };
}
