-- Follow the system dark/light setting. A manual pin wins: prefix + M-l / M-d
-- on the tmux side, or :ThemePin light|dark here -- both write the same state
-- file, so nvim and tmux never disagree.
--
-- Detection itself lives in the `system-theme` script (WSL registry, then the
-- XDG portal, then GNOME) so there is exactly one implementation to keep right.
-- The inline branch below is the fallback for a machine that has the config but
-- not the script -- typically Windows, where `nvim/` is shared but `linux/bin`
-- is not deployed.

local STATE = vim.env.XDG_STATE_HOME and vim.env.XDG_STATE_HOME .. '/system-theme' or vim.fn.expand '~/.local/state/system-theme'
local LEGACY_STATE = vim.fn.expand '~/.psmux-theme.state' -- the psmux pin on Windows
local KEY = [[HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]]

local function apply(mode)
  if vim.g.system_theme == mode then return end
  vim.g.system_theme = mode
  vim.o.background = mode
  vim.cmd.colorscheme(mode == 'light' and 'tokyonight-day' or 'tokyonight-night')
end

local function read_pin()
  for _, file in ipairs { STATE, LEGACY_STATE } do
    if vim.fn.filereadable(file) == 1 then
      local pin = (vim.fn.readfile(file)[1] or ''):match '^pin:(%a+)'
      if pin then return pin end
    end
  end
end

--- Fallback used only when `system-theme` is not installed.
local function detect_inline()
  -- WSL reaches the Windows registry through interop, but only under the exact
  -- name `reg.exe` -- a bare `reg` is not on the Linux PATH.
  local reg = vim.fn.has 'win32' == 1 and 'reg' or 'reg.exe'
  if vim.fn.executable(reg) == 0 then return apply 'dark' end
  vim.system(
    { reg, 'query', KEY, '/v', 'AppsUseLightTheme' },
    { text = true },
    vim.schedule_wrap(function(out) apply((out.stdout or ''):match '0x1' and 'light' or 'dark') end)
  )
end

local function detect()
  local pin = read_pin()
  if pin then return apply(pin) end
  if vim.fn.executable 'system-theme' == 0 then return detect_inline() end
  vim.system({ 'system-theme' }, { text = true }, vim.schedule_wrap(function(out) apply(vim.trim(out.stdout or '') == 'light' and 'light' or 'dark') end))
end

vim.api.nvim_create_user_command('ThemePin', function(opts)
  local arg = opts.args ~= '' and opts.args or nil
  local cmd = arg and { 'system-theme', '--pin', arg } or { 'system-theme', '--unpin' }
  vim.system(cmd, {}, vim.schedule_wrap(detect))
end, {
  nargs = '?',
  complete = function() return { 'light', 'dark' } end,
  desc = 'Pin the theme to light|dark, or unpin with no argument',
})

-- FocusGained covers alt-tabbing back after flipping the system setting, but
-- not `prefix + M-l` in a pane nvim is already focused in -- tmux writes the
-- state file and nvim never hears about it. fs_poll closes that gap; it stats
-- one small file, and unlike fs_event it behaves the same on every filesystem.
vim.api.nvim_create_autocmd({ 'VimEnter', 'FocusGained' }, { callback = detect })

local poll = vim.uv.new_fs_poll()
if poll then
  vim.fn.mkdir(vim.fs.dirname(STATE), 'p')
  poll:start(STATE, 2000, vim.schedule_wrap(detect))
  vim.api.nvim_create_autocmd('VimLeavePre', { callback = function() poll:stop() end })
end

detect()
