-- Follow the Windows dark/light setting; a psmux theme pin (prefix + M-l / M-d) wins.
local STATE = vim.fn.expand '~/.psmux-theme.state'
local KEY = [[HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]]

local function apply(mode)
  if vim.g.system_theme == mode then return end
  vim.g.system_theme = mode
  vim.o.background = mode
  vim.cmd.colorscheme(mode == 'light' and 'tokyonight-day' or 'tokyonight-night')
end

local function detect()
  local pinned = vim.fn.filereadable(STATE) == 1 and (vim.fn.readfile(STATE)[1] or ''):match '^pin:(%a+)'
  if pinned then return apply(pinned) end
  -- AppsUseLightTheme: 0x1 = light, missing/0x0 = dark
  vim.system(
    { 'reg', 'query', KEY, '/v', 'AppsUseLightTheme' },
    { text = true },
    vim.schedule_wrap(function(out)
      apply((out.stdout or ''):match '0x1' and 'light' or 'dark')
    end)
  )
end

-- ponytail: no polling — re-checked when nvim regains focus, which covers every
-- realistic way you flip the system theme. Add a vim.uv timer if that ever bites.
vim.api.nvim_create_autocmd({ 'VimEnter', 'FocusGained' }, { callback = detect })
detect()
