{
  programs.fish = {
    enable = true;

		shellAliases = {
			nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#g14";
			nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#g14";

      hms = "sudo nixos-rebuild switch --flake ~/.dotnix#g14";

      school = "cd /home/edward/Documents/school";
    };
  };
}
