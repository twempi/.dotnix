{
  programs.fish = {
    enable = true;

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/.dotnix#t480s";
      nrb = "sudo nixos-rebuild boot --flake ~/.dotnix#t480s";

      hms = "home-manager switch --flake ~/.dotnix#edward-t480s";

      v = "nvim";
      vi = "nvim";
      vim = "nvim";

      t = "tmux";

      ls = "eza --icons=auto --classify --group-directories-first --header --time-style=long-iso";
      la = "eza -la --icons=auto --classify --group-directories-first --header --time-style=long-iso";
      tree = "eza --tree --icons=auto --classify --group-directories-first --header --time-style=long-iso";

      g = "git";
      gs = "git status";
      gc = "git commit";
      ga = "git add";
      gpl = "git pull";
      gpu = "git push";
      gd = "git diff --output-indicator-new=' ' --output-indicator-old=' '";
      gch = "git checkout";
      gnb = "git checkout -b";
      gac = "git add . && git commit";
      grs = "git restore --staged .";
      gre = "git restore";
      gr = "git remote";
      gcl = "git clone";
      gl = "git log --graph --abbrev-commit --decorate --format=format:'%C(bold green)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold yellow)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all";
      gt = "git ls-tree -r main --name-only";
      grm = "git remote";
      gb = "git branch";
      gf = "git fetch";

      school = "cd /home/edward/Documents/school";
    };
  };
}
