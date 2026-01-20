{
  imports = [
    ./modules.nix
  ];

  home = {
    username = "edward";
    homeDirectory = "/home/edward";
    stateVersion = "25.05";
    sessionPath = [
      "$HOME/.local/bin"
    ];
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
