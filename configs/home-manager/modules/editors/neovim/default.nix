{
  config,
  lib,
  inputs,
  hostname,
  pkgs,
  ...
}: let
  homeConfigName = "${config.home.username}-${hostname}";
  stylixBase16Names = [
    "base00"
    "base01"
    "base02"
    "base03"
    "base04"
    "base05"
    "base06"
    "base07"
    "base08"
    "base09"
    "base0A"
    "base0B"
    "base0C"
    "base0D"
    "base0E"
    "base0F"
  ];

  stylixBase16 = lib.getAttrs stylixBase16Names config.lib.stylix.colors.withHashtag;

  stylixCacheKey = builtins.substring 0 12 (
    builtins.hashString "sha256" (builtins.toJSON stylixBase16)
  );

  luasnip-latex-snippets-nvim =
    config.wrappers.neovim.nvim-lib.mkPlugin
    "luasnip-latex-snippets"
    inputs.luasnip-latex-snippets-nvim;

  dotnixClipboard = pkgs.callPackage ../../cli/clipboard/package.nix {};
in {
  imports = [
    inputs.nixWrapperModules.homeModules.neovim
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

      stylix = {
        colors = stylixBase16;
        polarity = config.stylix.polarity;
        cacheKey = stylixCacheKey;
      };
    };

    specs = {
      lze = {
        lazy = false;
        data = with pkgs.vimPlugins; [
          lze
          lzextras
        ];
      };

      ui = {
        lazy = false;
        data = with pkgs.vimPlugins; [
          plenary-nvim
          nvim-web-devicons
          nvchad-ui
          base46
          snacks-nvim
          transparent-nvim
        ];
      };

      plugins = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          # snacks-nvim
          # transparent-nvim
          # plenary-nvim
          # nvim-web-devicons
          # base46
          # nvchad-ui
          nvim-treesitter.withAllGrammars
          nvim-treesitter-textobjects

          nvim-dap-go
          lazydev-nvim
          nvim-lspconfig
          vim-startuptime
          blink-cmp
          blink-cmp-spell
          lualine-nvim
          lualine-lsp-progress
          gitsigns-nvim
          which-key-nvim
          nvim-lint
          conform-nvim
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          yazi-nvim
          luasnip
          friendly-snippets
          nvim-autopairs
          sqlite-lua
          tabout-nvim
          luasnip-latex-snippets-nvim

          render-markdown-nvim
          typst-preview-nvim
          markdown-preview-nvim
          bullets-vim

          mini-ai
          mini-icons
          mini-surround
          mini-splitjoin

          vimtex
        ];
      };
    };
  };
}
