{
  # GPU mode menu for the g14 keybinds. amane-dmenu comes from the amane module in the desktop profile.
  flake.modules.homeManager.g14-gpu = {pkgs, ...}: {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "amane-gpu";
        runtimeInputs = with pkgs; [supergfxctl libnotify coreutils gnugrep gnused];
        text = builtins.readFile ./gpu.sh;
      })
    ];
  };
}
