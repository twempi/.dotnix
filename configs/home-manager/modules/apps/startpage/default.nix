{pkgs, ...}: {
  xdg.configFile."startpage" = {
    source = ./startpage;
    recursive = true;
  };
  systemd.user.services.startpage-server = {
    Unit = {
      Description = "Startpage local web server";
      After = ["network.target"];
    };
    Service = {
      WorkingDirectory = "/home/edward/.config/startpage";
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8000 --bind 127.0.0.1";
      Restart = "on-failure";
    };
    Install = {WantedBy = ["default.target"];};
  };
}
