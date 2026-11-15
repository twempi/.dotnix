{
  flake.modules.nixos.t480s-hermes-agent = {
    # Read by the Home Manager activation of t480s-hermes-agent, which runs as edward.
    sops.secrets.hermes_env = {
      sopsFile = ../../../../../../../secrets/hermes.yaml;
      owner = "edward";
    };

    # The Hermes gateway is a user service; keep it running without a login session.
    users.users.edward.linger = true;
  };
}
