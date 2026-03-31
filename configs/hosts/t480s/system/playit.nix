{ config, pkgs, lib, ... }:

let
  playit = pkgs.stdenv.mkDerivation {
    pname = "playit-agent";
    version = "0.16.2";

    src = pkgs.fetchurl {
      url = "https://github.com/playit-cloud/playit-agent/releases/download/v0.16.2/playit-linux-amd64";
      sha256 = lib.fakeSha256;
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 $src $out/bin/playit
    '';
  };
in
{
  systemd.services.playit = {
    description = "playit.gg tunnel agent";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${playit}/bin/playit";
      Restart = "always";
      RestartSec = 5;
      DynamicUser = true;
      StateDirectory = "playit";
      WorkingDirectory = "/var/lib/playit";
    };
  };
}
