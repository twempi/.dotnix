{inputs, ...}: {
  flake.modules.homeManager.zen-browser = {
    imports = [
      inputs.zen-browser.homeModules.beta
    ];

    stylix.targets.zen-browser = {
      enable = true;
      profileNames = ["edward"];
    };

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = false;
      nativeMessagingHosts = [];

      profiles.edward = {
        settings = {
          "zen.workspaces.continue-where-left-off" = true;
          "zen.workspaces.natural-scroll" = true;
          "zen.view.compact.hide-tabbar" = true;
          "zen.view.compact.hide-toolbar" = true;
          "zen.view.compact.animate-sidebar" = false;
          "zen.welcome-screen.seen" = true;
          "zen.urlbar.behavior" = "default";
          "zen.urlbar.replace-newtab" = false;
          "zen.view.sidebar-expanded" = false;
          "zen.view.sidebar-expanded.on-hover" = false;
          "zen.window-sync.enabled" = false;
          "zen.window-sync.prefer-unsynced-windows" = false;
        };

        mods = [
          "1b88a6d1-d931-45e8-b6c3-bfdca2c7e9d6" # Remove Tab X
          # "a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec" # Cleaner URL Bar
          "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
          "72f8f48d-86b9-4487-acea-eb4977b18f21" # Better Ctrl Tab Panel
          "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
        ];

        containersForce = true;
        containers = {
          Personal = {
            color = "purple";
            icon = "fingerprint";
            id = 1;
          };
          Shopping = {
            color = "yellow";
            icon = "dollar";
            id = 2;
          };
        };
      };
    };
  };
}
