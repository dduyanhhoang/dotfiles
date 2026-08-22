-- exercise the two branches of theme.lua's detection, no config loaded
local KEY = [[HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]]
assert(('pin:dark'):match '^pin:(%a+)' == 'dark')
assert(('pin:light'):match '^pin:(%a+)' == 'light')
assert(('light'):match '^pin:(%a+)' == nil)   -- unpinned state file falls through to registry
local out = vim.system({ 'reg', 'query', KEY, '/v', 'AppsUseLightTheme' }, { text = true }):wait()
print('registry ->', (out.stdout or ''):match '0x1' and 'light' or 'dark')
print('all asserts passed')
