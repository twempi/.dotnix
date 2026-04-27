return {
  "chomosuke/typst-preview.nvim",
  enabled = true,
  ft = "typst",
  opts = {
    follow_cursor = true,
    port = 1234,
  },

  keys = {
    { "<leader>t", "<nop>", desc = "[t]ypst" },
    { "<leader>tp", "<cmd>typstpreview<cr>", desc = "preview (browser)" },
    -- { "<leader>tp", "<cmd>openpdf<cr>", desc = "preview pdf (sioyek)" },
    { "<leader>tp", "<cmd>openpdf<cr>", desc = "preview pdf (zathura)" },
  },

  config = function()
    vim.api.nvim_create_user_command("OpenPdf", function()
      local filepath = vim.api.nvim_buf_get_name(0)

      if filepath:match("%.typ$") then
        local pdf_path = filepath:gsub("%.typ$", ".pdf")
        -- vim.system({ "sioyek", pdf_path }, { detach = true })
        vim.system({ "zathura", pdf_path }, { detach = true })
      else
        vim.notify("Not a Typst file", vim.log.levels.WARN)
      end
    end, {})
  end,
}
