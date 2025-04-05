local binary = require("supermaven-nvim.binary.binary_handler")
local listener = require("supermaven-nvim.document_listener")
local log = require("supermaven-nvim.logger")
local u = require("supermaven-nvim.util")

local loop = u.uv

local M = {}

M.is_running = function()
  return binary:is_running()
end

M.start = function()
  if M.is_running() then
    log:warn("Supermaven is already running.")
    return
  else
    log:trace("Starting Supermaven...")
  end
  vim.g.SUPERMAVEN_DISABLED = 0
  binary:start_binary()
  listener.setup()
end

M.stop = function()
  vim.g.SUPERMAVEN_DISABLED = 1
  if not M.is_running() then
    log:warn("Supermaven is not running.")
    return
  else
    log:trace("Stopping Supermaven...")
  end
  listener.teardown()
  binary:stop_binary()
end

M.restart = function()
  if M.is_running() then
    M.stop()
  end
  M.start()
end

M.toggle = function()
  if M.is_running() then
    M.stop()
  else
    M.start()
  end
end

M.use_free_version = function()
  binary:use_free_version()
end

M.use_pro = function()
  binary:use_pro()
end

M.logout = function()
  binary:logout()
end

M.show_log = function()
  local log_path = log:get_log_path()
  if log_path ~= nil then
    vim.cmd.tabnew()
    vim.cmd(string.format(":e %s", log_path))
  else
    log:warn("No log file found to show!")
  end
end

M.clear_log = function()
  local log_path = log:get_log_path()
  if log_path ~= nil then
    loop.fs_unlink(log_path)
  else
    log:warn("No log file found to remove!")
  end
end

M.trigger_completion = function()
  local buffer = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local context = {
    document_text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n"),
    cursor = cursor,
    file_name = vim.api.nvim_buf_get_name(buffer),
  }

  require("supermaven-nvim.binary.binary_handler"):provide_inline_completion_items(buffer, cursor, context)
end

return M
