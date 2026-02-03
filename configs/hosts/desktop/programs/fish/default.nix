{
  programs.fish = {
    enable = true;

		shellAliases = {
			nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#desktop";
			nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#desktop";

      school = "cd /home/edward/Documents/school";
    };
  };
}
