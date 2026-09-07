# Conventions for this repo

## Commits and comments

Never mention AI assistants, agents, or model names anywhere that lands in the
repository. That covers commit messages and trailers, PR titles and bodies,
code comments, documentation, and branch names.

- No `Co-Authored-By:` or session/trailer lines naming a tool or model.
- Commits are authored as `D Duy Anh Hoang
  <137117837+dduyanhhoang@users.noreply.github.com>`, matching
  `git/gitconfig.linux` and the rest of the history.
- Branch names describe the change (`shadow/fix-tmux-copy-mode-clipboard`), and
  carry no tool name.

Write commit messages the way the existing history does: a short subject, then
prose explaining what was wrong, why, and how the fix was verified.

## Layout

`sync.sh` (Linux/WSL) and `sync.ps1` (Windows) copy tracked config files to and
from their live locations; `save` pulls them in, `apply` pushes them out. The
path map at the top of each script is the source of truth for what is tracked —
add new files there. Package installs are never scripted; they are documented in
`linux/packages.md` and the Windows lists instead.
