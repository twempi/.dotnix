{lib, ...}: {
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        source = lib.mkForce "${./../../../../../home-manager/modules/cli/fastfetch/ascii/mimikyu.txt}";
        type = lib.mkForce "file";
      };
    };
  };
}
