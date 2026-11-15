{
  flake.modules.nixos.homelab = {...}: {
    # Docker (rootless only; no root daemon and no docker group)
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };

    # Podman
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
