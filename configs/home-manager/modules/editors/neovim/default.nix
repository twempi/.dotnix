{
  config,
  inputs,
  hostname,
  pkgs,
  ...
}: let
  homeConfigName = "${config.home.username}-${hostname}";
  dotnixClipboard = pkgs.callPackage ../../cli/clipboard/package.nix {};
in {
  imports = [
    inputs.nixWrapperModules.homeModules.neovim
    ./stylix.nix
    ./plugins.nix
  ];

  wrappers.neovim = {
    enable = true;
    binName = "nvim";

    settings = {
      aliases = ["vim" "homeVim"];
      config_directory = ./.;
      info_plugin_name = "dotnix-nvim-info";
    };

    hosts = {
      python3.nvim-host.enable = true;
      node.nvim-host.enable = true;
    };

    runtimePkgs = with pkgs; [
      lazygit
      nodejs
      fd
      tree-sitter
      dotnixClipboard
      wl-clipboard
      xclip
      xsel

      # Lua
      lua-language-server
      stylua
      lua51Packages.luacheck

      # Nix
      nixd
      alejandra
      statix
      deadnix

      # Go
      gopls
      delve
      golangci-lint
      gotools
      go-tools
      go

      # Typst
      tinymist
      typstyle

      # Markdown
      marksman
      markdownlint-cli2

      # Latex
      texlab
      texlivePackages.latexmk
      texlivePackages.latexindent
      texlivePackages.chktex

      # C
      clang
      clang-tools

      vscode-langservers-extracted
      jq

      # Yaml
      yaml-language-server
      yamlfmt

      taplo

      # Python
      pyright
      black
      isort
      ruff

      # Bash
      bash-language-server
      shfmt
      shellcheck

      # Typescript
      typescript-language-server
      prettier
      prettierd
      eslint_d

      # Arduino
      arduino-language-server
      arduino-cli

      # Assembly
      asm-lsp
      asmfmt
    ];

    runtimeLibs = with pkgs; [
      sqlite
    ];

    env = {
      PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
    };

    info = {
      nixdExtras = {
        nixpkgs = ''import ${pkgs.path} {}'';

        nixosOptions = ''
          (builtins.getFlake "${inputs.self}").nixosConfigurations.${hostname}.options
        '';

        homeManagerOptions = ''
          (builtins.getFlake "${inputs.self}").homeConfigurations.${homeConfigName}.options
        '';
      };

      sqlite.libsqlite3 = "${pkgs.sqlite.out}/lib/libsqlite3.so";
    };
  };
}
