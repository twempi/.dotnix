return {
	{ "nvim-web-devicons", lazy = false },

	{
		"base46",
		lazy = false,
		priority = 1000,
		after = function()
			require("base46").load_all_highlights()
		end,
	},

	{
		"nvchad-ui",
		lazy = false,
		before = function()
			require("lze").trigger_load({
				"nvim-web-devicons",
				"base46",
			})
		end,
		after = function()
			require("nvchad")
		end,
	},

	-- Draws the sign column and feeds the git section of the NvChad statusline.
	{
		"gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		after = function()
			require("gitsigns").setup({
				on_attach = function(bufnr)
					local gs = require("gitsigns")

					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
					end

					map("n", "]h", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gs.nav_hunk("next")
						end
					end, "Next hunk")

					map("n", "[h", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gs.nav_hunk("prev")
						end
					end, "Previous hunk")

					map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
					map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
					map("v", "<leader>gs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, "Stage selected lines")
					map("v", "<leader>gr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, "Reset selected lines")
					map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
					map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
					map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
					map("n", "<leader>gb", function()
						gs.blame_line({ full = true })
					end, "Blame line")
					map("n", "<leader>gd", gs.diffthis, "Diff against index")
					map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
				end,
			})
		end,
	},
}
