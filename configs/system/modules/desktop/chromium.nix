{
  flake.modules.nixos.chromium = {...}: {
    # The BrowserThemeColor policy would override Helium's per-profile theme
    # colour, which Home Manager sets so the theme switcher can change it.
    stylix.targets.chromium.enable = false;

    programs.chromium = {
      enable = true;
      homepageLocation = "https://t480s.tailae03d0.ts.net/";

      extraOpts = {
        SpellcheckEnabled = true;
        SpellcheckLanguage = ["en-US"];
      };
    };

    environment.etc."/brave/policies/managed/GroupPolicy.json".text = ''
      {
        "BraveRewardsDisabled": true,
        "BraveWalletDisabled": true,
        "TorDisabled": true,
        "BraveVPNDisabled": 1,
        "BraveAIChatEnabled": 0,
        "BraveNewsDisabled": 1
      }
    '';
  };
}
