{
  flake.modules.homeManager.zen-browser = {pkgs, ...}: {
    programs.zen-browser.profiles.edward.search = {
      force = true;
      default = "google";
      engines = let
        nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        chatgptIcon = "https://chatgpt.com/favicon.ico";
      in {
        "Nix Packages" = {
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                {
                  name = "type";
                  value = "packages";
                }
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = nixIcon;
          definedAliases = ["np"];
        };

        "Nix Options" = {
          urls = [
            {
              template = "https://search.nixos.org/options";
              params = [
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = nixIcon;
          definedAliases = ["nop"];
        };

        "ChatGPT" = {
          urls = [
            {
              template = "https://chatgpt.com/";
            }
          ];
          icon = chatgptIcon;
          definedAliases = ["gpt"];
        };

        bing.metaData.hidden = "true";
      };
    };
  };
}
