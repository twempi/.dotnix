{inputs, ...}: {
  imports = [
    inputs.helium.nixosModules.helium
  ];

  home-manager.sharedModules = [
    inputs.helium.homeModules.helium

    ({...}: {
      programs.helium = {
        enable = true;
        defaultBrowser = false;

        extraPolicies = {
          HomepageLocation = "file:///home/edward/.config/startpage/index.html";
          HomepageIsNewTabPage = false;
          ShowHomeButton = true;
          NewTabPageLocation = "file:///home/edward/.config/startpage/index.html";

          SpellcheckEnabled = true;
          SpellcheckLanguage = ["en-US"];
        };

        preferences = {
          browser.show_home_button = true;
        };
      };
    })
  ];
}
