return {
	"typst-preview.nvim",
	ft = { "typst" },
	after = function()
		require("typst-preview").setup({
			follow_cursor = true,
			port = 1234,
		})

		vim.api.nvim_create_user_command("OpenPdf", function()
			local filepath = vim.api.nvim_buf_get_name(0)

			if filepath:match("%.typ$") then
				local pdf_path = filepath:gsub("%.typ$", ".pdf")
				vim.system({ "zathura", pdf_path }, { detach = true })
			else
				vim.notify("Not a Typst file", vim.log.levels.WARN)
			end
		end, {})

		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, {
				buffer = true,
				desc = desc,
				silent = true,
			})
		end

		map("<leader>tp", "<cmd>TypstPreview<CR>", "Preview (browser)")
		map("<leader>tP", "<cmd>OpenPdf<CR>", "Preview PDF (Zathura)")
	end,
}
