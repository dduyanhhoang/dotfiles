# ---- prompt ----
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\robbyrussell.omp.json" | Invoke-Expression

# ---- readline ----
Set-PSReadLineOption -EditMode Windows
try { Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView } catch { }  # no VT when redirected
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# ---- fzf keys (must come AFTER EditMode: setting it resets the keymap) ----
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# ---- zoxide (z / zi) ----
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# ---- aliases ----
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls { eza --icons --group-directories-first @args }
function ll { eza -l --icons --git --group-directories-first @args }
function la { eza -la --icons --git --group-directories-first @args }
function lt { eza --tree --level=2 --icons @args }
function cat { bat --paging=never @args }
Set-Alias lg lazygit

$env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
$env:FZF_DEFAULT_OPTS    = '--height 40% --layout=reverse --border'


# ---- navigation ----
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function mkcd { param([Parameter(Mandatory)]$Path) New-Item -ItemType Directory -Force $Path | Set-Location }
function which { (Get-Command @args).Source }

