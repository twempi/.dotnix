{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ryzenadj];

  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    tlp.enable = false;
  };

  hardware.amdgpu.initrd.enable = true;
  programs.corectrl.enable = true;
  users.users.edward.extraGroups = ["corectrl"];

  systemd.services.ryzenadj-limits = {
    description = "Apply Ryzen power limits";
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.ryzenadj}/bin/ryzenadj \
          --stapm-limit=25000 \
          --fast-limit=30000 \
          --slow-limit=28000 \
          --tctl-temp=85
      '';
    };
  };

  systemd.timers.ryzenadj-limits = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
      Unit = "ryzenadj-limits.service";
    };
  };
}
