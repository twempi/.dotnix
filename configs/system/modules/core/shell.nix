{pkgs, ...}: {
  environment.shells = with pkgs; [bashInteractive fish];

  programs.fish.enable = true;

  users = {
    users.edward.shell = pkgs.fish;
    defaultUserShell = pkgs.fish;
  };
}
