{pkgs, ...}: {
  imports = [
    ./general.nix
    ./keybinds.nix
    ./env.nix
    ./windowrules.nix
  ];

  stylix.targets.hyprland.enable = true;

  # hyprland
  wayland.windowManager.hyprland = {
    systemd.enable = false;
    enable = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      hyprland.default = ["hyprland" "gtk"];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
}
