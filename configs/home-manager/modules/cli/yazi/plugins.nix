{inputs, ...}: {
  flake.modules.homeManager.yazi = {pkgs, ...}: let
    pref-by-location-plugin = pkgs.fetchFromGitHub {
      owner = "boydaihungst";
      repo = "pref-by-location.yazi";
      rev = "919b2d0f23c61943dce74b38f23af75fde3f4828";
      sha256 = "sha256-RxwX8UH025AsN5NlcPyJ8neake40F7iRRC/zeL0AD9k";
    };

    convert-plugin = pkgs.fetchFromGitHub {
      owner = "twempi";
      repo = "convert.yazi";
      rev = "97946adfc3ab769c4586a9c1780c475c6699f820";
      sha256 = "sha256-cD4s1NXz09+DmBcYb95OMUez1RMiro7Y4YzRPKI0wtA=";
    };
  in {
    programs.yazi = {
      plugins = {
        "full-border" = pkgs.yaziPlugins.full-border;
        "smart-enter" = pkgs.yaziPlugins.smart-enter;
        "bunny" = "${inputs.bunny-yazi}";
        "pref-by-location" = pkgs.applyPatches {
          name = "pref-by-location-patched";
          src = pref-by-location-plugin;

          postPatch = ''
            substituteInPlace main.lua \
              --replace-fail '.scheme' '.spec'
          '';
        };
        "convert" = convert-plugin;
      };

      initLua = ''
        require("full-border"):setup()
        require("pref-by-location"):setup({})

        require("bunny"):setup({
          hops = {
            { key = "/", path = "/" },
            { key = "t", path = "/tmp" },
            { key = "h", path = "~", desc = "Home" },
            { key = "d", path = "~/Downloads/", desc = "Downloads" },
            { key = "D", path = "~/Documents", desc = "Documents" },
            { key = "c", path = "~/.config", desc = "Config" },
            { key = "n", path = "~/.dotnix", desc = "Nix Config" },
            { key = "p", path = "~/Pictures", desc = "Pictures" },
            { key = { "l", "s" }, path = "~/.local/share", desc = "Local share" },
            { key = { "l", "b" }, path = "~/.local/bin", desc = "Local bin" },
            { key = { "l", "t" }, path = "~/.local/state", desc = "Local state" },
            { key = { "s", "s" }, path = "/mnt/Storage", desc = "Storage" },
            { key = { "s", "p" }, path = "/mnt/Storage/Pictures", desc = "Storage Pictures" },
            { key = { "s", "D" }, path = "/mnt/Storage/Documents", desc = "Storage Documents" },
          },
          desc_strategy = "path",
          ephemeral = true,
          tabs = true,
          notify = false,
          fuzzy_cmd = "fzf",
        })
      '';
    };
  };
}
