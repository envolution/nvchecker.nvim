-- plugin/nvchecker.lua
if vim.g.loaded_nvchecker then
	return
end
vim.g.loaded_nvchecker = 1

-- Auto-setup with default config if not already configured
if not vim.g.nvchecker_setup_done then
	require("nvchecker").setup()
	vim.g.nvchecker_setup_done = true
end
