{inputs, ...}: {
  flake.modules.homeManager.neovim = {
    config,
    hostname,
    pkgs,
    ...
  }: let
    pkgsStable = import inputs.nixpkgs-stable {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
    homeConfigName = "${config.home.username}-${hostname}";
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
        pkgsStable.typescript-language-server
        prettier
        prettierd
        eslint_d

        # Assembly
        asm-lsp
        asmfmt
      ];

      info = {
        nixdExtras = {
          nixpkgs = ''import ${pkgs.path} {}'';

          nixosOptions = ''
            (builtins.getFlake "${config.home.homeDirectory}/.dotnix").nixosConfigurations.${hostname}.options
          '';

          # nixd crashes while completing `programs.*` for the desktop Home Manager profile.
          enableHomeManagerOptions = hostname == "t480s";

          homeManagerOptions = ''
            (builtins.getFlake "${config.home.homeDirectory}/.dotnix").homeConfigurations.${homeConfigName}.options
          '';
        };

        sqlite.libsqlite3 = "${pkgs.sqlite.out}/lib/libsqlite3.so";
      };
    };
  };
}
