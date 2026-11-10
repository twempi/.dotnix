{
  # The iCal addresses the Amane shell's calendar tab reads, one per line.
  flake.modules.nixos.calendar = {
    sops.secrets.google_calendars = {
      sopsFile = ../../../../secrets/calendar.yaml;
      owner = "edward";
      mode = "0400";
    };
  };
}
