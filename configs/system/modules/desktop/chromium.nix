{
  stylix.targets.chromium.enable = true;

  programs.chromium = {
    enable = true;
    homepageLocation = "https://t480s.tailae03d0.ts.net/";
    extraOpts = {
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = ["en-US"];
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
}
