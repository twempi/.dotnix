{pkgs, config, lib, ...}: {
    programs.localsend = {
        enable = true;
        openFirewall = true;
      };
  }
