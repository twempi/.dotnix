{inputs, ...}: {
  flake.modules.homeManager.hermes-agent = {pkgs, ...}: let
    reaPlugins = pkgs.fetchFromGitHub {
      owner = "NousResearch";
      repo = "hermes-official-plugins";
      rev = "1690b63a4790cb821fb6a319ba524815d4e09411";
      hash = "sha256-F9Q0ltt5lwH/L6+boUYn1VTbeyiPhSG8viWfPmXZUO4=";
    };
    memoryWikiPlugins = pkgs.fetchFromGitHub {
      owner = "NousResearch";
      repo = "hermes-official-plugins";
      rev = "e7a218f26db88426ab3e7376f0e000b6e356f5e7";
      hash = "sha256-zDjiWUVmWUPAyasy74mUuh+d/dpBi1SBh7GZvuTjxcI=";
    };
  in {
    imports = [
      inputs.hermes-agent.homeManagerModules.default
    ];

    programs.hermes-agent = {
      enable = true;
      desktop = {
        enable = true;
      };
    };

    home.file = {
      ".hermes/plugins/rea".source = "${reaPlugins}/rea";
      ".hermes/plugins/memory-wiki".source = "${memoryWikiPlugins}/memory-wiki";
    };
  };
}
