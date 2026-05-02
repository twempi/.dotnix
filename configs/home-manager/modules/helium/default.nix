{inputs, ...}: {
  imports = [inputs.helium.homeModules.helium];

  programs.helium = {
    enable = true;
    defaultBrowser = false;

    extraFlags = [
      "--force-dark-mode"
    ];

    extraPolicies = {
      HomepageLocation = "https://start.duckduckgo.com";
      PasswordManagerEnabled = true;
    };

    preferences = {
      browser.show_home_button = true;
    };
  };
}
