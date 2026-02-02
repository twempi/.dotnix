{pkgs, ...}: {
  programs.git = {
    enable = true;
    package = pkgs.git.override {withLibsecret = true;};

    settings = {
      user = {
        name = "midboob";
        email = "edwarddan72@gmail.com";
      };

      credential.helper = "${pkgs.git.override {withLibsecret = true;}}/bin/git-credential-libsecret";

      core = {
        compression = 9;
        editor = "nvim";
        whitespace = "error";
      };

      init.defaultBranch = "main";

      status = {
        branch = true;
        short = true;
        showStash = true;
        showUntrackedFiles = "all";
      };

      diff = {
        context = 3;
        renames = "copies";
      };

      log = {
        abbrevCommit = true;
        graphColors = "blue,yellow,cyan,magenta,green,red";
      };

      safe = {
        directory = [
          "/mnt/Storage/Documents/notes"
        ];
      };

      pull = {
        rebase = true;
      };

      rebase = {
        autoStash = true; # optional but nice: stashes local changes during rebase
      };

      commit = {
        template = "${./template}";
      };
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = ["https://github.com" "https://gist.github.com"];
    };
  };
}
