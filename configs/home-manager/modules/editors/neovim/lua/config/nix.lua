local M = {}

local info_name = vim.g.nix_info_plugin_name
local ok, info = false, {}

if type(info_name) == "string" and info_name ~= "" then
	ok, info = pcall(require, info_name)
end

if not ok or type(info) ~= "table" then
	info = {}
end

M.raw = info
M.is_nix = ok

function M.get(default, ...)
	if ok then
		local call_ok, value = pcall(info, default, ...)
		if call_ok then
			return value
		end
	end

	local current = info
	for _, key in ipairs({ ... }) do
		if type(current) ~= "table" then
			return default
		end

		current = current[key]
		if current == nil then
			return default
		end
	end

	return current
end

return M
