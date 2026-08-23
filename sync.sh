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
  printf 'open a new shell, then run :checkhealth in nvim\n'
fi

printf '\n\033[32m%s done.\033[0m\n' "$mode"
