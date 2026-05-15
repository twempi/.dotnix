{
  programs.fish = {
    enable = true;

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#desktop";
      nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#desktop";

      hms = "home-manager switch --flake ~/.dotnix#edward-desktop";

      school = "cd ~/Documents/school";
    };
  };
}
