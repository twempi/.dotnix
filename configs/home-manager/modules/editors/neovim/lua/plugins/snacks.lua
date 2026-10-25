local function sqlite3_path()
	return require("config.nix").get(nil, "info", "sqlite", "libsqlite3")
end

return {
	{
		"snacks.nvim",
		lazy = false,
		priority = 1000,
		before = function()
			require("lze").trigger_load({ "sqlite.lua", "nvim-web-devicons" })
		end,

		after = function()
			local opts = {
				animate = { enabled = true },

				dashboard = {
					enabled = true,
					preset = {
						header = [[


⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣾⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⣛⡛⠹⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⣌⣙⣉⣥⣬⣭⣉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠄⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⠏⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⡟⠀⢀⣠⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣤⣤⣤⣾⣿⣿⠋⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⠀⢰⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢠⣶⣶⣶⣤⣴⣶⣿⣿⣿⣿⣿⡟⣋⣭⣥⣤⣴⣶⣿⣷⡆⠀⠀⢸⣿⣿⣿⣿⣿⠀⣿⣿⢛⣉⣉⣉⣩⣤⣶⣶⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢰⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⣿⣿⣿⣿⣿⠀⣿⣇⢸⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣰⣶⣶⣦⡈⢻⣿⣿⣿⣿⣿⣿⡿⠛⠘⣿⣿⣿⣿⣿⣿⡿⠋⣠⣶⠀⠀⣿⣿⣿⣿⣿⠀⢻⣿⡄⠻⣿⣿⣿⣿⣿⣿⡟⢀⣤⣴⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣦⣙⠿⣿⠿⠛⠁⠀⠀⠀⣿⣿⣿⣿⣿⡿⠁⣼⣿⣿⠀⠀⣿⣿⣿⣿⣿⠀⠈⣿⣷⠀⠹⣿⣿⣿⣿⠀⠀⣾⡿⠛⣛⣛⣛⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠸⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡇⠰⣿⣿⣿⠀⠀⣿⣿⣿⣿⣿⠀⠰⠿⠟⠀⠀⢿⣿⣿⣿⡆⢠⡟⣠⣾⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢻⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡇⠀⠻⣿⣿⠀⠀⣿⣿⣿⣿⣿⡀⠀⣴⣿⡆⠀⠸⣿⣿⣿⣿⠀⢰⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡇⢠⡀⢿⡿⠀⠀⢸⣿⣿⣿⣿⡇⠀⢿⣿⣧⠀⠀⢿⣿⣿⣿⣇⢸⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠘⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⠀⣸⣿⣶⣦⠀⠀⢸⣿⣿⣿⣿⡇⠀⠀⠻⢿⣦⡀⢸⣿⣿⣿⣿⡄⢻⣧⠙⢿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢹⣿⣿⡇⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⡟⠀⣿⣿⠟⠁⠀⠀⢸⣿⣿⣿⣿⣷⡀⠀⠀⠀⠈⠀⢸⣿⣿⣿⣿⣷⡀⢻⠀⠀⢻⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣷⡀⠛⠁⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣶⣄⠀⢀⣴⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⣿⣿⣿⣿⣶⣄⡀⠀⠀⠀
⠀⠀⠀⠈⣿⣿⡇⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⣼⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀
⠀⠀⠀⠀⣿⣿⣇⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣾⣿⣿⣿⣿⠿⢿⣿⣿⣿⠟⠁⠘⣿⣿⣿⣿⡿⠿⢿⣿⣿⣿⣿⡇⢹⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀
⠀⠀⠀⢀⣿⣿⣿⣄⠀⠀⠘⢿⣿⣿⣿⠟⢋⣉⣭⣭⣍⣁⡀⠀⠘⠿⠟⣩⣴⣶⣶⣮⣍⣥⣶⣶⡄⠻⠟⣋⣥⣶⣶⣦⣝⠛⣛⡛⠃⢸⡿⠟⣋⣉⣛⠻⠏⠙⠇⠀
⠀⠀⢠⣿⣿⣿⣿⣿⣷⣄⠀⠀⢀⣤⣤⣴⣿⣿⣿⣿⣿⣿⣿⣿⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⢠⣶⣿⣿⣿⣿⣷⣀⣿⣆⠀
⠀⢀⣿⣿⠿⠻⠿⢿⣿⣿⠇⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆
⠀⠈⣿⢇⣶⣿⣷⣶⣦⣄⡀⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡘⢿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⠇⠈⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏
⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⠋⠀⠀⠘⣿⣿⣿⣿⣿⣿⠇⠀⠀⢠⣿⣿⣿⣿⣿⣿⡿⠋⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀
⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⡟⠀⠀⢠⣿⣿⣿⣿⣿⣿⠋⠀⠀⢀⣾⣿⣿⣿⣿⣿⡿⠛⠉⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣆⠀⠀⠀⣼⣿⣿⣿⡿⠀⠀⣰⣿⣿⣿⣿⣿⠟⠁⠀⠀⣠⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⢻⣿⣿⣿⣿⣿⣧⠀⢠⣿⣿⣿⣿⡇⢠⣾⣿⣿⣿⣿⣿⠋⠀⠀⣀⣴⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣷⣄⠸⣿⣿⣿⣿⣿⣿⣴⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⠃⣾⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⡿⢸⣿⣿⣿⣿⣿⢰⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⡿⢋⣉⣍⡀⠙⠿⣿⣿⣿⠟⢠⣿⣿⣤⣉⣭⡄⣾⣿⣿⣿⣿⣿⠈⠻⠿⠿⠛⠉⢿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡇⢸⣿⣿⣧⢰⣷⣶⣤⣴⣆⣾⣿⣿⣿⣿⣿⣧⣿⣿⣿⣿⣿⠟⢰⣿⣶⣶⣿⠇⠈⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠷⠘⢿⣿⣿⡀⢿⣿⣿⣿⡟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⣠⣾⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⢿⣷⡌⢿⣿⣿⡇⣿⣿⣿⠏⣴⣶⣿⡿⠟⢁⣠⣾⣿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠉⠙⠁⠈⠛⠋⠀⠛⠛⠋⠠⣶⠿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ]],
					},
					sections = {
						{ section = "header" },
						{
							padding = 2,
							align = "center",
							text = {
								{ "Neovim :: Welcome back pɹɐʍpǝ", hl = "Title" },
							},
						},
					},
				},

				explorer = { enabled = false },
				bigfile = { enabled = true },
				picker = {
					enabled = true,
					ui_select = true,
					db = {
						sqlite3_path = sqlite3_path(),
					},
				},

				input = {
					enabled = true,
					backdrop = false,
					position = "float",
					border = true,
					title_pos = "center",
				},

				image = {
					enabled = true,

					resolve = function(file, src)
						if not src or src == "" then
							return nil
						end

						-- Handle Obsidian-style image sizes:
						-- image.png|500
						-- image.png\|500
						local clean_src = src:gsub("\\|.*$", ""):gsub("|.*$", "")

						if clean_src == "" then
							return nil
						end

						-- Let Snacks handle URLs and absolute paths.
						if clean_src:match("^%w[%w+.-]*://") or clean_src:sub(1, 1) == "/" then
							return clean_src
						end

						local image_dirs = {
							vim.fn.expand("~/Documents/notes/990 Attachments"),
						}

						for _, dir in ipairs(image_dirs) do
							local full_path = vim.fs.normalize(dir .. "/" .. clean_src)
							if vim.uv.fs_stat(full_path) then
								return full_path
							end
						end

						-- Safe relative fallback for files next to the current document.
						if file and file ~= "" then
							local dir = vim.fs.dirname(file)
							if dir then
								local full_path = vim.fs.normalize(dir .. "/" .. clean_src)
								if vim.uv.fs_stat(full_path) then
									return full_path
								end
							end
						end

						-- Returning nil lets Snacks continue with its own resolver.
						return nil
					end,

					doc = {
						enabled = true,
						inline = true,
						float = false,
						max_width = 80,
						max_height = 40,
					},

					math = { enabled = false },
				},

				indent = {
					enabled = true,
					priority = 1,
					char = "|",
					animate = { enabled = true },
				},

				notifier = { enabled = true },
				scope = { enabled = true },
				scroll = { enabled = true },
				words = { enabled = true },
				toggle = { enabled = true },

				styles = {
					input = {
						position = "float",
						backdrop = false,
						border = true,
						title_pos = "center",
					},
				},
			}

			local Snacks = require("snacks")
			Snacks.setup(opts)

			-- These normally initialize on UIEnter, but health checks run headless before that event.
			if Snacks.input and Snacks.input.enable then
				Snacks.input.enable()
			end
			if Snacks.picker and Snacks.picker.select then
				vim.ui.select = Snacks.picker.select
			end
		end,

		keys = {
			{
				"<leader>n",
				function()
					require("snacks").picker.notifications()
				end,
				desc = "Notifications",
			},
			{
				"<C-\\>",
				function()
					require("snacks").terminal.open()
				end,
				desc = "Snacks Terminal",
			},
			{
				"<leader>_",
				function()
					require("snacks").lazygit.open()
				end,
				desc = "Snacks LazyGit",
			},

			{
				"<leader><leader>",
				function()
					require("snacks").picker.smart()
				end,
				desc = "Smart Find Files",
			},
			{
				"<leader>bb",
				function()
					require("snacks").picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>ff",
				function()
					require("snacks").picker.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					require("snacks").picker.git_files()
				end,
				desc = "Find Git Files",
			},

			{
				"<leader>sb",
				function()
					require("snacks").picker.lines()
				end,
				desc = "Buffer Lines",
			},
			{
				"<leader>sB",
				function()
					require("snacks").picker.grep_buffers()
				end,
				desc = "Grep Open Buffers",
			},
			{
				"<leader>sg",
				function()
					require("snacks").picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>sw",
				function()
					require("snacks").picker.grep_word()
				end,
				mode = { "n", "x" },
				desc = "Grep Word/Visual",
			},

			{
				"<leader>sd",
				function()
					require("snacks").picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>sD",
				function()
					require("snacks").picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},

			{
				"<leader>sh",
				function()
					require("snacks").picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>xl",
				function()
					require("snacks").picker.loclist()
				end,
				desc = "Location List",
			},
			{
				"<leader>sm",
				function()
					require("snacks").picker.marks()
				end,
				desc = "Marks",
			},
			{
				"<leader>sM",
				function()
					require("snacks").picker.man()
				end,
				desc = "Man Pages",
			},
			{
				"<leader>xq",
				function()
					require("snacks").picker.qflist()
				end,
				desc = "Quickfix List",
			},
			{
				"<leader>sR",
				function()
					require("snacks").picker.resume()
				end,
				desc = "Resume",
			},
			{
				"<leader>su",
				function()
					require("snacks").picker.undo()
				end,
				desc = "Undo History",
			},
		},
	},

	{ "sqlite.lua", dep_of = "snacks.nvim" },
}
