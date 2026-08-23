#!/usr/bin/env bash
#
#   ./sync.sh save    -> copy live config files INTO this repo (run before commit)
#   ./sync.sh apply   -> copy repo files OUT to their live locations (new machine)
#
# Linux/WSL counterpart to sync.ps1. A repo path ending in '/' is a directory
# and gets mirrored (destination wiped first), matching sync.ps1's behaviour.
#
# Package installs are NOT scripted here -- see linux/packages.md. apt needs a
# password prompt and the version managers (bob, volta) each want their own
# ordering, so they stay a deliberate manual step.

set -uo pipefail

mode=${1:-save}
case $mode in
  save|apply) ;;
  *) printf 'usage: %s [save|apply]\n' "$0" >&2; exit 2 ;;
esac

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# repo-relative path -> live path.
# Shared with Windows: nvim/ and bat/config are byte-identical on both sides;
# the nvim config branches at runtime on `vim.fn.has 'win32'`.
map=(
  'nvim/|'"$HOME"'/.config/nvim'
  'bat/config|'"$HOME"'/.config/bat/config'
  'git/gitconfig.linux|'"$HOME"'/.gitconfig'
  'linux/bashrc|'"$HOME"'/.bashrc'
  'linux/tmux.conf.local|'"$HOME"'/.config/tmux/tmux.conf.local'
  'linux/tmux/theme-dark.conf|'"$HOME"'/.config/tmux/theme-dark.conf'
  'linux/tmux/theme-light.conf|'"$HOME"'/.config/tmux/theme-light.conf'
  # Listed file by file on purpose. A 'linux/bin/' directory entry would mirror,
  # and mirroring wipes the destination first -- ~/.local/bin also holds claude,
  # uv, bob and tree-sitter, none of which this repo tracks.
  'linux/bin/system-theme|'"$HOME"'/.local/bin/system-theme'
  'linux/bin/tmux-theme|'"$HOME"'/.local/bin/tmux-theme'
  'linux/bin/tmux-theme-watch|'"$HOME"'/.local/bin/tmux-theme-watch'
  'linux/bin/theme-doctor|'"$HOME"'/.local/bin/theme-doctor'
)

warn() { printf '\033[33mwarning:\033[0m %s\n' "$1" >&2; }

for entry in "${map[@]}"; do
  key=${entry%%|*}
  live=${entry#*|}
  in_repo=$repo/${key%/}

  if [[ $mode == save ]]; then src=$live;    dst=$in_repo
  else                         src=$in_repo; dst=$live
  fi

  if [[ ! -e $src ]]; then warn "missing: $src"; continue; fi

  mkdir -p "$(dirname -- "$dst")"
  if [[ $key == */ ]]; then
    rm -rf -- "$dst"
    cp -r -- "$src" "$dst"
    # nvim/ is a git checkout upstream; never carry its metadata into the repo
    rm -rf -- "$dst/.git"
  else
    cp -f -- "$src" "$dst"
  fi
  printf '%s\n' "$key"
done

if [[ $mode == apply ]]; then
  printf '\n'
  for c in nvim node tree-sitter gh; do
    command -v "$c" >/dev/null || warn "$c not on PATH -- see linux/packages.md"
  done
  # These two own ~/.bashrc and ~/.config/tmux/. Their installers overwrite what
  # apply just wrote, so they have to come first; warn if they are not there yet.
  [[ -r $HOME/.oh-my-bash/oh-my-bash.sh ]] || warn 'Oh My Bash missing -- ~/.bashrc has no prompt until it is installed'
  [[ -e $HOME/.config/tmux/tmux.conf ]]    || warn 'Oh my tmux! missing -- tmux.conf.local has nothing to extend'
  printf 'open a new shell, then run :checkhealth in nvim\n'
fi

printf '\n\033[32m%s done.\033[0m\n' "$mode"
