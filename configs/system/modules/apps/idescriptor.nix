{
  flake.modules.nixos.idescriptor = {
    programs.idescriptor = {
      enable = true;
      users = ["edward"];
    };
  };
}
