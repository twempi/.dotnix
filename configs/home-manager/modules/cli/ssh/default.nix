{
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = ["~/.ssh/id_ed25519"];
        AddKeysToAgent = "yes";
        IdentitiesOnly = true;
      };

      desktop = {
        HostName = "100.103.126.2";
        User = "edward";
      };

      g14 = {
        HostName = "100.113.111.52";
        User = "edward";
      };

      t480s = {
        HostName = "100.107.176.54";
        User = "edward";
      };
    };
  };
}
