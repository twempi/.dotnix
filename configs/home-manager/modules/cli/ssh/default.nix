{ pkgs, lib, config, ... }: {
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    matchBlocks = {
      "github.com" = {
        host = "github.com";
        user = "git";
        identityFile = [ "~/.ssh/id_ed25519" ];
        addKeysToAgent = "yes";
        # optionally:
        identitiesOnly = true;
      };
    };
  };
}
