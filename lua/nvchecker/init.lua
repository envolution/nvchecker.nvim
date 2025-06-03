-- lua/nvchecker/init.lua
local M = {}

-- Plugin configuration
M.config = {
	auto_run = true,
	show_success_message = true,
	timeout = 30000, -- 30 seconds
	window = {
		height = 10,
		border = "rounded",
	},
}

-- Internal state
local running_jobs = {}
local output_buffer = nil
local output_window = nil

-- Utility functions
local function is_nvchecker_file(filename)
	return filename and filename:match(".*nvchecker%.toml$")
end

local function create_output_window(content)
	-- Close existing window if open
	if output_window and vim.api.nvim_win_is_valid(output_window) then
		vim.api.nvim_win_close(output_window, true)
	end

	-- Create or reuse buffer
	if not output_buffer or not vim.api.nvim_buf_is_valid(output_buffer) then
		output_buffer = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(output_buffer, "buftype", "nofile")
		vim.api.nvim_buf_set_option(output_buffer, "swapfile", false)
		vim.api.nvim_buf_set_option(output_buffer, "filetype", "nvchecker-output")
	end

	-- Set buffer content
	local lines = vim.split(content, "\n")
	vim.api.nvim_buf_set_lines(output_buffer, 0, -1, false, lines)

	-- Calculate window dimensions
	local width = math.min(vim.o.columns - 4, 120)
	local height = math.min(#lines + 2, M.config.window.height)
	local row = vim.o.lines - height - 3
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create floating window
	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = M.config.window.border,
		title = " nvchecker output ",
		title_pos = "center",
		style = "minimal",
	}

	output_window = vim.api.nvim_open_win(output_buffer, false, win_config)

	-- Set window options
	vim.api.nvim_win_set_option(output_window, "wrap", false)
	vim.api.nvim_win_set_option(output_window, "cursorline", true)

	-- Auto-close window after 10 seconds
	vim.defer_fn(function()
		if output_window and vim.api.nvim_win_is_valid(output_window) then
			vim.api.nvim_win_close(output_window, true)
		end
	end, 10000)
end

local function show_message(msg, level)
	level = level or vim.log.levels.INFO
	vim.notify(msg, level, { title = "nvchecker" })
end

local function run_nvchecker(filepath)
	-- Cancel any existing job for this file
	if running_jobs[filepath] then
		vim.fn.jobstop(running_jobs[filepath])
	end

	show_message("Running nvchecker for " .. vim.fn.fnamemodify(filepath, ":t"))

	local output = {}
	local start_time = vim.fn.reltime()

	running_jobs[filepath] = vim.fn.jobstart({ "nvchecker", "-c", filepath }, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.list_extend(output, data)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.list_extend(output, data)
			end
		end,
		on_exit = function(_, code)
			running_jobs[filepath] = nil
			local duration = vim.fn.reltimestr(vim.fn.reltime(start_time))

			local result_lines = {}
			table.insert(result_lines, string.format("nvchecker completed in %ss (exit code: %d)", duration, code))
			table.insert(result_lines, string.format("Config: %s", filepath))
			table.insert(result_lines, "")

			-- Filter out empty lines from output
			local filtered_output = {}
			for _, line in ipairs(output) do
				if line and line ~= "" then
					table.insert(filtered_output, line)
				end
			end

			if #filtered_output > 0 then
				table.insert(result_lines, "Output:")
				vim.list_extend(result_lines, filtered_output)
			else
				table.insert(result_lines, "No output generated.")
			end

			if code == 0 then
				if M.config.show_success_message then
					create_output_window(table.concat(result_lines, "\n"))
				end
			else
				show_message("nvchecker failed with exit code " .. code, vim.log.levels.ERROR)
				create_output_window(table.concat(result_lines, "\n"))
			end
		end,
	})

	if running_jobs[filepath] == 0 then
		show_message("Failed to start nvchecker process", vim.log.levels.ERROR)
		running_jobs[filepath] = nil
		return
	end

	-- Set timeout
	vim.defer_fn(function()
		if running_jobs[filepath] then
			vim.fn.jobstop(running_jobs[filepath])
			running_jobs[filepath] = nil
			show_message("nvchecker timed out", vim.log.levels.WARN)
		end
	end, M.config.timeout)
end

-- Public API
function M.run_current_file()
	local filepath = vim.api.nvim_buf_get_name(0)
	if not is_nvchecker_file(filepath) then
		show_message("Current file is not an nvchecker config file", vim.log.levels.WARN)
		return
	end

	if not vim.fn.filereadable(filepath) then
		show_message("File does not exist or is not readable", vim.log.levels.ERROR)
		return
	end

	run_nvchecker(filepath)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	-- Create autocommand group
	local group = vim.api.nvim_create_augroup("nvchecker", { clear = true })

	-- Auto-run on nvchecker.toml files
	if M.config.auto_run then
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			group = group,
			pattern = "*nvchecker.toml",
			callback = function()
				local filepath = vim.api.nvim_buf_get_name(0)
				vim.defer_fn(function()
					run_nvchecker(filepath)
				end, 100) -- Small delay to ensure file is written
			end,
			desc = "Auto-run nvchecker on save",
		})
	end

	-- Create user commands
	vim.api.nvim_create_user_command("NvCheckerRun", M.run_current_file, {
		desc = "Run nvchecker on current file",
	})

	vim.api.nvim_create_user_command("NvCheckerToggle", function()
		M.config.auto_run = not M.config.auto_run
		show_message("Auto-run " .. (M.config.auto_run and "enabled" or "disabled"))
	end, {
		desc = "Toggle nvchecker auto-run",
	})

	-- Set up keymaps for nvchecker files
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "toml",
		callback = function()
			local filepath = vim.api.nvim_buf_get_name(0)
			if is_nvchecker_file(filepath) then
				vim.keymap.set("n", "<leader>nr", M.run_current_file, {
					buffer = true,
					desc = "Run nvchecker",
				})
			end
		end,
	})
end

return M
