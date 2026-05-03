{
  stylix.targets.chromium.enable = true;

  programs.chromium = {
    enable = true;
    homepageLocation = "file:///home/edward/.config/startpage/index.html";
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
