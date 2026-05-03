return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  enabled = true,
  opts = {
    preset = "helix",
    win = {
      title = false,
      padding = { 1, 2 },
    },
    spelling = {
      enabled = true,
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    wk.add({
      { "<leader><leader>", group = "buffer" },
      { "<leader>c", group = "[c]ode" },
      { "<leader>d", group = "[d]ocument" },
      { "<leader>g", group = "[g]it" },
      { "<leader>r", group = "[r]ename" },
      { "<leader>f", group = "[f]ind" },
      { "<leader>s", group = "[s]earch" },
      { "<leader>w", group = "[w]orkspace" },
    })
  end,
}
