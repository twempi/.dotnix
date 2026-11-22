{
  flake.modules.nixos.games = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      steam
      steam-unwrapped
      steam-run
      (lutris.override {
        extraPkgs = pkgs: [
          pkgs.wineWow64Packages.stable
          pkgs.winetricks
          # Lutris' default wine version is a Proton build, which it launches through umu
          pkgs.umu-launcher
        ];
      })
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
  };
}
