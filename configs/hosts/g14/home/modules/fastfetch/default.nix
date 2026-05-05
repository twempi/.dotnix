{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        source = "${./../../../../../home-manager/modules/cli/fastfetch/ascii/mimikyu.txt}";
        type = "file";
      };
    };
  };
}
