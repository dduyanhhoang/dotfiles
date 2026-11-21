local wezterm = require 'wezterm'
local is_windows = wezterm.target_triple:find 'windows' ~= nil

local function scheme()
  return wezterm.gui.get_appearance():find 'Dark' and 'Catppuccin Mocha' or 'Catppuccin Latte'
end

-- wezterm 20240203 khong nap lai config khi Windows doi dark/light, nen doi
-- scheme ngay trong update-status (chay moi ~1s cho tung cua so).
wezterm.on('update-status', function(window)
  local want = scheme()
  if window:effective_config().color_scheme ~= want then
    window:set_config_overrides { color_scheme = want }
  end
end)

return {
  color_scheme = scheme(),

  default_prog = is_windows and { 'pwsh.exe', '-NoLogo' } or { 'bash', '-l' },

  font = wezterm.font 'JetBrainsMono Nerd Font Mono',
  font_size = 13.0,
  harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' },

  front_end = 'OpenGL',
  max_fps = 120,
  animation_fps = 1,
  cursor_blink_rate = 0,

  -- kieu Ghostty: bo title bar (giu vien de resize), an tab bar, 1 terminal
  window_decorations = 'RESIZE',
  enable_tab_bar = false,
  keys = {
    -- tab bi an nen chan Ctrl+Shift+T de khong mo tab "vo hinh"
    { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.DisableDefaultAssignment },
  },
}
