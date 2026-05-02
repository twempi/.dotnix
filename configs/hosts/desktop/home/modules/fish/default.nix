{
  programs.fish = {
    enable = true;

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#desktop";
      nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#desktop";

      hms = "sudo nixos-rebuild switch --flake ~/.dotnix#desktop";

      school = "cd /mnt/Storage/Documents/school";
    };
  };
}
