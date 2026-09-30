{
  config,
  inputs,
  pkgs,
  ...
}: let
  luasnip-latex-snippets-nvim =
    config.wrappers.neovim.nvim-lib.mkPlugin
    "luasnip-latex-snippets"
    inputs.luasnip-latex-snippets-nvim;

  vellumRenderer = pkgs.importNpmLock.buildNodeModules {
    npmRoot = "${inputs.vellum-nvim}/render";
    nodejs = pkgs.nodejs;
    derivationArgs.env.PUPPETEER_SKIP_DOWNLOAD = "true";
  };

  vellum-nvim = (config.wrappers.neovim.nvim-lib.mkPlugin "vellum.nvim" inputs.vellum-nvim).overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        ln -s ${vellumRenderer}/node_modules "$out/render/node_modules"
      '';
  });
in {
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
        vellum-nvim
      ];
    };
  };
}
