{inputs, ...}: {
  flake.modules.homeManager.hermes-agent = {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    # CLI only. Enabling services.hermes-agent would make the config Nix-managed
    # and block `hermes setup`, so keys and model stay in ~/.hermes for now.
    programs.hermes-agent = {
      enable = true;
      desktop = {
        enable = true;
      };
    };
  };
}
