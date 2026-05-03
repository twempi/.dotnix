return {

  { import = "nvchad.blink.lazyspec" },

  {
    "saghen/blink.cmp",
    enabled = true,
    event = "VeryLazy",
    dependencies = {
      "ribru17/blink-cmp-spell",
    },
    opts = {
      completion = {
        menu = { border = "rounded" },
        documentation = {
          window = { border = "rounded" },
        },
      },

      keymap = { preset = "enter" },
      appearance = { nerd_font_variant = "mono" },
      signature = { enabled = true },

      sources = {
        default = {
          "lsp",
          "path",
          "snippets",
          "buffer",
          "spell",
        },

        -- ✅ providers MUST live here in NVChad
        providers = {
          spell = {
            name = "Spell",
            module = "blink-cmp-spell",
            opts = {
              enable_in_context = function()
                return vim.wo.spell
              end,
            },
          },
        },
      },
    },
  },
}
