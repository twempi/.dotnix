{...}: {
  imports = [
    ./general.nix
    ./keybinds.nix
    ./env.nix
    ./windowrules.nix
  ];

  stylix.targets.hyprland.enable = true;

  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    configType = "hyprlang";
    package = null;
    portalPackage = null;
  };
}
