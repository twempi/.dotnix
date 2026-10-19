{
  flake.modules.homeManager.desktop-fish = {
    programs.fish = {
      enable = true;

      shellAliases = {
        nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#desktop";
        nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#desktop";

        hms = "home-manager switch --flake ~/.dotnix#edward-desktop && theme-switch --restore";

        school = "cd ~/Documents/school";
      };
    };
  };
}
