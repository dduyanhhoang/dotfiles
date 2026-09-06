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
  save|apply) shift ;;
  *) printf 'usage: %s [save|apply] [--dry-run] [--no-backup]\n' "$0" >&2; exit 2 ;;
esac

dry_run=false
backup=true
for arg in "$@"; do
  case $arg in
    --dry-run)   dry_run=true ;;
    --no-backup) backup=false ;;
    *) printf 'usage: %s [save|apply] [--dry-run] [--no-backup]\n' "$0" >&2; exit 2 ;;
  esac
done

# One stamp for the whole run, so a single apply's backups sort together.
stamp=$(date +%Y%m%d%H%M%S)

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

  # Nothing to do when the two already agree -- keeps a re-run from producing a
  # drawer full of identical backups.
  if [[ $key == */ ]]; then
    diff -rq --exclude=.git -- "$src" "$dst" >/dev/null 2>&1 && { printf '%s (unchanged)\n' "$key"; continue; }
  else
    cmp -s -- "$src" "$dst" && { printf '%s (unchanged)\n' "$key"; continue; }
  fi

  # apply overwrites files this repo does not own; on a machine that was already
  # in use that is someone's .bashrc or nvim config, and unlike the repo side it
  # has no git history to recover from. Move it aside first.
  note=
  if [[ $mode == apply && $backup == true && -e $dst ]]; then
    note=" (backed up -> ${dst##*/}.bak-$stamp)"
    $dry_run || mv -- "$dst" "$dst.bak-$stamp"
  fi

  if $dry_run; then
    printf '%s -> %s%s\n' "$key" "${dst/#$HOME/\~}" "$note"
    continue
  fi

  mkdir -p "$(dirname -- "$dst")"
  if [[ $key == */ ]]; then
    rm -rf -- "$dst"
    cp -r -- "$src" "$dst"
    # nvim/ is a git checkout upstream; never carry its metadata into the repo
    rm -rf -- "$dst/.git"
  else
    cp -f -- "$src" "$dst"
  fi
  printf '%s%s\n' "$key" "$note"
done

if [[ $mode == apply ]] && ! $dry_run; then
  printf '\n'
  for c in nvim node tree-sitter gh; do
    command -v "$c" >/dev/null || warn "$c not on PATH -- see linux/packages.md"
  done
  # These two own ~/.bashrc and ~/.config/tmux/. Their installers overwrite what
  # apply just wrote, so they have to come first; warn if they are not there yet.
  [[ -r $HOME/.oh-my-bash/oh-my-bash.sh ]] || warn 'Oh My Bash missing -- ~/.bashrc has no prompt until it is installed'

  # An older Oh my tmux! installs to ~/.tmux.conf, whose sibling local file is
  # ~/.tmux.conf.local. tmux prefers the XDG path when both exist, but with only
  # the old one present the tmux.conf.local written above is never read -- and
  # nothing reports that, it simply has no effect.
  if [[ -e $HOME/.tmux.conf && ! -e $HOME/.config/tmux/tmux.conf ]]; then
    warn 'Oh my tmux! is installed at ~/.tmux.conf -- tmux will not read ~/.config/tmux/tmux.conf.local'
    warn '  reinstall it so it lands under ~/.config/tmux/, or copy the file to ~/.tmux.conf.local'
  elif [[ ! -e $HOME/.config/tmux/tmux.conf ]]; then
    warn 'Oh my tmux! missing -- tmux.conf.local has nothing to extend'
  fi

  # tmux_conf_copy_to_os_clipboard=true only does something if Oh my tmux! finds
  # a command to pipe into. With none, it skips the rewrite and `y` silently goes
  # back to copying into the tmux buffer alone -- same probe order as upstream.
  if ! command -v xsel >/dev/null && ! command -v xclip >/dev/null \
     && ! command -v wl-copy >/dev/null && ! command -v pbcopy >/dev/null \
     && ! command -v clip.exe >/dev/null && [[ ! -c /dev/clipboard ]]; then
    warn 'no clipboard command found -- tmux copy mode `y` will not reach the OS clipboard'
    if [[ -n ${WSL_DISTRO_NAME:-} ]]; then
      warn '  under WSL this is clip.exe: check /mnt/?/windows/system32 survived the PATH filter in ~/.bashrc'
    else
      warn '  install wl-clipboard (Wayland) or xsel (X11) -- see linux/packages.md'
    fi
  fi

  # nvim/ needs vim.pack, which lands in 0.12. On 0.11 the config does not
  # degrade -- it raises on PackChanged and nothing after it loads.
  if command -v nvim >/dev/null; then
    v=$(nvim --version | head -1 | sed 's/^NVIM v//;s/[^0-9.].*//')
    if [[ -n $v ]] && ! printf '0.12.0\n%s\n' "$v" | sort -V -C; then
      warn "nvim $v is too old -- nvim/ uses vim.pack and needs 0.12+ (see linux/packages.md)"
    fi
  fi
  printf 'open a new shell, then run :checkhealth in nvim\n'
fi

if $dry_run; then
  printf '\n\033[32m%s dry-run -- nothing was written.\033[0m\n' "$mode"
else
  printf '\n\033[32m%s done.\033[0m\n' "$mode"
fi
