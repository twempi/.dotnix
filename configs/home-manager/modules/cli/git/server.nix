{config, ...}: {
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "midboob";
        email = "edwarddan72@gmail.com";
      };

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
          "${config.home.homeDirectory}/Documents/notes"
        ];
      };

      pull.rebase = true;
      rebase.autoStash = true;
      commit.template = "${./template}";
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
