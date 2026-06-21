{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    seanime
    mpv
    ffmpeg
    qbittorrent
  ];

  networking.firewall.allowedTCPPorts = [43211];
}
