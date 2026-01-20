{pkgs, ...}: {
  enviroment.systemPackages = with pkgs; [
    uv
  ];

  programs.uv = {
    enable = true;
  };
}
