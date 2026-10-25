{
  flake.modules.homeManager.neovim = {pkgs, ...}: {
    wrappers.neovim.specs = {
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
          blink-cmp
          blink-cmp-spell
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
