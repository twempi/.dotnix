{ pkgs, ... }: {

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

  programs.gamemode.enable = true;
}
