{
  flake.modules.nixos.handy = {...}: {
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660"
    '';
  };
}
