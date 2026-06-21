{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    seanime
    ffmpeg
    mpv
    qbittorrent-nox
  ];

  networking.firewall.allowedTCPPorts = [
    43211
    8080
  ];

  systemd.services.seanime = {
    description = "Seanime media server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      User = "edward";
      WorkingDirectory = "/home/edward";
      ExecStart = "${pkgs.seanime}/bin/seanime";
      Restart = "on-failure";
      RestartSec = 5;

      Environment = [
        "SEANIME_SERVER_HOST=0.0.0.0"
        "SEANIME_SERVER_PORT=43211"
      ];
    };
  };
}
