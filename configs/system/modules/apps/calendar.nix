{
  # The Google sign-in that `amane-calendar --login` prints, for the Amane shell's calendar tab.
  flake.modules.nixos.calendar = {
    sops.secrets.google_calendar_account = {
      sopsFile = ../../../../secrets/calendar.yaml;
      owner = "edward";
      mode = "0400";
    };
  };
}
