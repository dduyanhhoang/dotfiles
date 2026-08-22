# dotfiles (Windows)

Windows equivalent of a Linux dotfiles repo. Config files live in their normal
locations; this repo holds copies plus one script to move them either way.

```powershell
.\sync.ps1 save    # live files -> repo   (run before committing)
.\sync.ps1 apply   # repo -> live files   (new machine)
```

## What's tracked

| Path | Live location |
|---|---|
| `powershell/` | `~\Documents\PowerShell\` (profile, execution policy, module list) |
| `psmux/` | `~\.psmux*.conf`, theme switcher + watcher |
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\` |
| `git/.gitconfig` | `~\.gitconfig` |
| `scoop/scoopfile.json` | `scoop export` / `scoop import` |

## New machine

1. Install scoop: `iwr -useb get.scoop.sh | iex`
2. `git clone <this repo> ~\dotfiles; cd ~\dotfiles; .\sync.ps1 apply`

`apply` runs `scoop import` (all apps: psmux, oh-my-posh, eza, bat, fzf, fd,
ripgrep, zoxide, lazygit, neovim, volta, ...) and installs the PowerShell modules.

Not tracked: secrets, anything under `~/.claude`, `*.bak` files, WT `state.json`.
