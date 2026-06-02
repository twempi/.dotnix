{pkgs, ...}: {
  environment = {
    localBinInPath = true;
    sessionVariables = {
      # Application Specific
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      MOZ_DBUS_REMOTE = "1";
      NIXOS_OZONE_WL = "1";
      PROTON_ENABLE_NGX_UPDATER = "1";
    };

    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";

      # BROWSER = "${pkgs.brave}/bin/brave";
      # DEFAULT_BROWSER = "${pkgs.brave}/bin/brave";
      BROWSER = "zen-beta";
      DEFAULT_BROWSER = "zen-beta";
    };
  };
}
