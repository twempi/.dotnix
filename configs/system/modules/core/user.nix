{
  flake.modules.nixos.user = {
    users.users.edward = {
      isNormalUser = true;
      extraGroups = ["wheel" "input" "networkmanager" "video" "dialout"];
    };
  };
}
