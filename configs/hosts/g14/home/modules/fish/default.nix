{
  programs.fish = {
    enable = true;

		shellAliases = {
			nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#g14";
			nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#g14";

      hms = "home-manager switch --flake ~/.dotnix#edward-g14";

      school = "cd /home/edward/Documents/school";
    };
  };
}
