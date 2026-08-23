# Linux / WSL packages

Everything `sync.sh apply` cannot install by copying a file. Written against
Ubuntu 26.04 on WSL2, which is what this is running on.

**On another machine.** The tracked config files are portable as they stand:
`linux/bashrc` derives `$OSH` from `$HOME`, skips the whole Windows-PATH block
unless `$WSL_DISTRO_NAME` is set, guards the Oh My Bash source, and gates every
CLI hook behind `command -v`. `nvim/`'s theme detector falls back to dark when
no registry is reachable. What is *not* portable is this file: only the apt
section below is Debian/Ubuntu-specific, so swap it for your package manager --
`bob`, `volta`, `tree-sitter` and `uv` all install the same way anywhere, since
each ships its own binary rather than a distro package.

## apt

Same CLI set as the scoop list on the Windows side. Ubuntu ships `bat` and `fd`
under different binary names (`batcat`, `fdfind`) to avoid clashes with other
packages -- `linux/bashrc` aliases them back.

```sh
sudo apt update && sudo apt install -y \
  bat eza fd-find fzf zoxide lazygit gh \
  ripgrep git make gcc curl unzip
```

## Neovim -- via bob, not apt

apt tracks a stable series (0.11.x). The kickstart config here uses `vim.pack`,
which only exists in **Neovim 0.12+**, so apt's build cannot load it at all.
[bob](https://github.com/MordechaiHadad/bob) manages Neovim versions and makes
the upgrade path a one-liner.

```sh
curl -fsSL -o bob.zip https://github.com/MordechaiHadad/bob/releases/latest/download/bob-linux-x86_64.zip
unzip bob.zip && install -m755 bob-linux-x86_64/bob ~/.local/bin/bob
bob install stable && bob use stable
```

| | |
|---|---|
| upgrade | `bob update --all` |
| roll back a bad release | `bob rollback` |
| list what is installed | `bob list` |

`linux/bashrc` puts `~/.local/share/bob/nvim-bin` on PATH.

## Node -- volta

Matches the Windows side. WSL inherits the Windows PATH, so `node` otherwise
resolves to `/mnt/c/.../scoop/apps/volta/...`, whose shim shells out to a
`volta` binary that does not exist inside WSL -- every call fails. `linux/bashrc`
strips those entries; volta then supplies a real Linux toolchain.

```sh
curl https://get.volta.sh | bash
volta install node@24
```

## tree-sitter CLI -- standalone binary, NOT volta

`volta install tree-sitter-cli` looks correct and then breaks parser builds.
nvim-treesitter compiles each grammar with the CWD inside the grammar's own
checkout, which contains a `package.json`; volta reads that, decides
`tree-sitter` must be a project-local dependency, finds none, and aborts with
`Could not locate executable`. Ship the real binary instead:

```sh
curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
  | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter
```

## uv

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Oh my bash + Oh my tmux

Both are cloned by their own installers; this repo tracks only the user-edited
config files (`linux/bashrc`, `linux/tmux.conf.local`).

```sh
# oh-my-bash -> ~/.oh-my-bash, replaces ~/.bashrc (sync.sh apply restores ours)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended

# oh-my-tmux -> ~/.local/share/tmux/oh-my-tmux, symlinks ~/.config/tmux/tmux.conf
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gpakosz/.tmux/master/install.sh)"
```

Order matters: run both **before** `sync.sh apply`, or their installers will
overwrite the configs it just laid down.

## Theme switching

`linux/bin/` needs `~/.local/bin` on PATH (`linux/bashrc` puts it there) and
`flock` for the watcher's single-instance lock -- part of `util-linux`, already
present on any normal install. On a desktop Linux box, `gdbus` (from
`glib2`/`libglib2.0-bin`) is what makes portal detection work; without it the
detector falls back to `gsettings` and then to dark.

## gh

Interactive, so it is not scripted:

```sh
gh auth login && gh auth setup-git
```

## Claude Code

```sh
curl -fsSL https://claude.ai/install.sh | bash
```
