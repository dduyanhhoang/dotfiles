| `nvim/` | `%LOCALAPPDATA%\nvim` — kickstart.nvim, relative numbers, telescope searches hidden+gitignored files, `lua/custom/plugins/theme.lua` follows Windows dark/light |

| `git/.gitconfig`# dotfiles (Windows)

Windows equivalent of a Linux dotfiles repo. Config files live in their normal
locations; this repo holds copies plus one script to move them either way.

```powershell
.\sync.ps1 save    # live files -> repo   (run before committing)
.\sync.ps1 apply   # repo -> live files   (new machine)
```

## What's tracked

| Path | Live location / role |
|---|---|
| `powershell/` | `~\Documents\PowerShell\` — profile, execution policy, `modules.txt` (PSFzf) |
| `psmux/` | `~\.psmux*.conf` — config, binds, dark/light themes, theme watcher + `.cmd` switcher |
| `nvim/` | `%LOCALAPPDATA%\nvim` — kickstart.nvim, relative numbers, telescope searches hidden+gitignored files, `lua/custom/plugins/theme.lua` follows Windows dark/light |
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\` |
| `git/.gitconfig` | `~\.gitconfig` |
| `scoop/scoopfile.json` | every scoop app — `scoop export` / `scoop import` |
| `winget/apps.txt` | winget-only apps (Nerd Font, Terminal, PowerShell 7, PowerToys, Warp) |

Neovim needs `mingw` + `make` (treesitter / telescope-fzf-native) — both are in the scoop list.
Check the theme detector with `nvim --clean -l nvim/theme-check.lua`.

CLI tools come from scoop: psmux, oh-my-posh, eza, bat, fzf, fd, ripgrep,
zoxide, lazygit, neovim, gh, volta, git, 7zip, curl, vscode.

## New machine

```powershell
iwr -useb get.scoop.sh | iex
git clone https://github.com/dduyanhhoang/dotfiles ~\dotfiles
cd ~\dotfiles; .\sync.ps1 apply
```

`apply` = scoop import + winget installs + `volta install node@24` + PowerShell
modules + copy every config into place. Restart the terminal after.

Installed by their own installers, not scripted here:
`irm https://claude.ai/install.ps1 | iex` (Claude Code), `irm https://astral.sh/uv/install.ps1 | iex` (uv).

## Notes

- `winget/apps.txt` is hand-curated on purpose — `winget export` pulls in VCLibs
  and runtime junk. Add a line when you install something winget-only.
- `sync.ps1 save` refreshes the scoop and PowerShell-module lists automatically.
- Not tracked: secrets, anything under `~/.claude`, `*.bak` files, WT `state.json`.
