# dotfiles

One machine, two environments: Windows and the WSL2 Ubuntu running inside it.
Config files live in their normal locations; this repo holds copies plus one
script per platform to move them either way.

```powershell
.\sync.ps1 save    # live files -> repo   (run before committing)
.\sync.ps1 apply   # repo -> live files   (new machine)
```

```sh
./sync.sh save              # same, from Linux/WSL
./sync.sh apply
./sync.sh apply --dry-run   # print what would be written, touch nothing
```

Each script only touches the paths in its own map, so they never fight over the
same file.

**On a machine that is already in use**, run `apply --dry-run` first. `apply`
overwrites `~/.bashrc`, `~/.gitconfig` and the whole of `~/.config/nvim`, and
nothing there has git history to fall back on -- so anything it is about to
replace is moved to `<name>.bak-<timestamp>` beside the original. Pass
`--no-backup` to skip that. Files that already match are reported `(unchanged)`
and left alone, so a second run neither rewrites nor re-backs-up anything.

## Shared

Byte-identical on both sides -- both sync scripts map these.

| Path | Windows | Linux/WSL |
|---|---|---|
| `nvim/` | `%LOCALAPPDATA%\nvim` | `~/.config/nvim` |
| `bat/config` | `~\scoop\persist\bat\config` | `~/.config/bat/config` |

`nvim/` is kickstart.nvim with relative numbers, telescope searching hidden and
gitignored files, pyright + ruff for Python, jsonls + yamlls for config files,
and `lua/custom/plugins/theme.lua` following the Windows dark/light setting.
Every platform difference inside it is a runtime `vim.fn.has 'win32'` branch,
never a separate file -- including the theme detector, which reaches the
registry as `reg` on Windows and `reg.exe` through WSL interop.

Plugin versions are pinned in `nvim/nvim-pack-lock.json` (`vim.pack`'s lockfile).

## Windows

| Path | Live location / role |
|---|---|
| `powershell/` | `~\Documents\PowerShell\` -- profile, execution policy, `modules.txt` (PSFzf) |
| `psmux/` | `~\.psmux*.conf` -- config, binds, dark/light themes, theme watcher + `.cmd` switcher |
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\` |
| `git/.gitconfig` | `~\.gitconfig` -- credential helpers point at scoop's `gh.exe` |
| `scoop/scoopfile.json` | every scoop app -- `scoop export` / `scoop import` |
| `winget/apps.txt` | winget-only apps (Nerd Font, Terminal, PowerShell 7, PowerToys, Warp) |

Neovim needs `mingw`, `make` and the `tree-sitter` CLI (parser compilation,
telescope-fzf-native) -- all three are in the scoop list.

CLI tools come from scoop: psmux, oh-my-posh, eza, bat, fzf, fd, ripgrep,
zoxide, lazygit, neovim, gh, volta, git, 7zip, curl, vscode.

### New machine

```powershell
iwr -useb get.scoop.sh | iex
git clone https://github.com/dduyanhhoang/dotfiles ~\dotfiles
cd ~\dotfiles; .\sync.ps1 apply
```

`apply` = scoop import + winget installs + `volta install node@24` + PowerShell
modules + copy every config into place. Restart the terminal after.

Installed by their own installers, not scripted here:
`irm https://claude.ai/install.ps1 | iex` (Claude Code), `irm https://astral.sh/uv/install.ps1 | iex` (uv).

## Linux / WSL

| Path | Live location / role |
|---|---|
| `linux/bashrc` | `~/.bashrc` -- Oh My Bash (robbyrussell), Windows-PATH filter, CLI hooks |
| `linux/tmux.conf.local` | `~/.config/tmux/tmux.conf.local` -- Oh my tmux! user config |
| `linux/tmux/theme-*.conf` | `~/.config/tmux/` -- dark and light palettes, ported from `psmux/` |
| `linux/bin/system-theme` | `~/.local/bin/` -- one detector shared by tmux and Neovim |
| `linux/bin/tmux-theme` | `~/.local/bin/` -- applies a palette; the Linux `.psmux-theme.cmd` |
| `linux/bin/tmux-theme-watch` | `~/.local/bin/` -- polls for system theme changes |
| `linux/bin/theme-doctor` | `~/.local/bin/` -- prints every light/dark signal and what each says |
| `linux/packages.md` | what to install and why -- apt, bob, volta, tree-sitter, uv |
| `git/gitconfig.linux` | `~/.gitconfig` -- same identity, native `gh` as credential helper |

### Dark / light

Same bindings as psmux, so the muscle memory carries over:

| | |
|---|---|
| `prefix + T` | follow the system again (drop the pin) |
| `prefix + M-l` | force light and pin |
| `prefix + M-d` | force dark and pin |
| `:ThemePin light\|dark` | the same, from inside Neovim (no argument unpins) |

`system-theme` is the only place detection is implemented -- WSL asks the
Windows registry through `reg.exe`, elsewhere it tries the XDG desktop portal
(`org.freedesktop.appearance`, so GNOME and KDE both answer) and then GNOME's
`color-scheme`/`gtk-theme` keys, falling back to dark. A pin lives in
`~/.local/state/system-theme` and outranks all of it.

tmux picks changes up from `tmux-theme-watch`, which polls every 3s -- the WSL
signal is a registry value with nothing to subscribe to, so polling is required
regardless, and it matches what `.psmux-theme-watch.ps1` already does. Neovim
watches that same state file with `fs_poll`, so `prefix + M-l` retints a pane
Neovim is already focused in, where `FocusGained` alone would never fire.

### Other differences from Windows

- **Neovim comes from [bob](https://github.com/MordechaiHadad/bob), not apt.**
  This config uses `vim.pack`, which needs Neovim 0.12+; apt ships the 0.11
  series. `bob update --all` upgrades, `bob rollback` undoes a bad release.
- **tmux needs `tmux_conf_24b_colour=true`, not `auto`.** Oh my tmux!'s
  auto-detection looks for `COLORTERM` or a `tput colors` of 16777216; Windows
  Terminal exports neither into WSL, so tmux never advertised `RGB` and
  downgraded every 24-bit colour to the 256 palette -- Neovim's theme visibly
  shifted the moment you opened tmux.
- **WSL inherits the Windows PATH**, which puts `scoop/shims` and the Windows
  volta ahead of nothing at all -- the volta shims call a `volta` binary that
  does not exist inside WSL, so `node` and `npm` fail outright. `linux/bashrc`
  filters `/mnt/*` down to an allowlist (system32 for `clip.exe`, PowerShell,
  WindowsApps, `code`, Warp, Codex); widen `_win_keep` there to add more back.

### New machine

`apply` only copies config files -- it installs nothing. Work through
`linux/packages.md` first; the warnings it prints at the end name whatever is
still missing.

Install Oh My Bash and Oh my tmux! **first** -- their installers overwrite
`~/.bashrc` and `~/.config/tmux/`, so running them after `apply` undoes it.

```sh
# see linux/packages.md for the full list and the reasoning
sudo apt update && sudo apt install -y bat eza fd-find fzf zoxide lazygit gh ripgrep make gcc
# ... oh-my-bash, oh-my-tmux, bob, volta, tree-sitter, uv ...
git clone https://github.com/dduyanhhoang/dotfiles ~/dotfiles
cd ~/dotfiles && ./sync.sh apply
gh auth login && gh auth setup-git
```

## Notes

- `winget/apps.txt` is hand-curated on purpose -- `winget export` pulls in VCLibs
  and runtime junk. Add a line when you install something winget-only.
- `sync.ps1 save` refreshes the scoop and PowerShell-module lists automatically.
  `sync.sh` does not install packages at all -- apt needs a password prompt and
  the version managers each want their own ordering. `linux/packages.md` is the
  hand-maintained record instead.
- `nvim/theme-check.lua` is currently an empty file.
- Not tracked: secrets, anything under `~/.claude`, `*.bak` files, WT `state.json`.
