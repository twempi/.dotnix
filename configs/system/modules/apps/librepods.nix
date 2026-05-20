{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      librepods = inputs.librepods.packages.${prev.stdenv.hostPlatform.system}.default;
    })
  ];

  programs.librepods.enable = true;

  users.users.edward.extraGroups = ["librepods"];

  hardware.bluetooth.settings = {
    General = {
      DeviceID = "bluetooth:004C:0000:0000";
    };
  };
}
