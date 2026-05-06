{lib, ...}: {
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        source = lib.mkForce "${./../../../../../home-manager/modules/cli/fastfetch/ascii/laying-cat.txt}";
        type = lib.mkForce "file";
      };
    };
  };
}
