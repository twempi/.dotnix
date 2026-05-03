{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.helium.nixosModules.helium
  ];

  environment.etc."chromium/policies/managed/helium-edward.json" = lib.mkIf
    (config.home-manager.users.edward.programs.helium.enable or false)
    {
      text = config.home-manager.users.edward.programs.helium.finalPolicyJson;
      mode = "0644";
    };
}
