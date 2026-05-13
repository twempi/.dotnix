{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    steam
    steam-unwrapped
    steam-run
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings.general = {
      renice = 10;
      softrealtime = "auto";
      ioprio = 0;
      inhibit_screensaver = 1;
      desiredgov = "performance";
    };
  };
}
