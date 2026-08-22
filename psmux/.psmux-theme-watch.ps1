# ~/.psmux-theme-watch.ps1 - theo doi theme Windows, dong bo sang psmux.
# Chay nen, mot ban duy nhat (mutex), tu thoat khi khong con psmux nao chay.
$mutex = New-Object System.Threading.Mutex($false, 'Local\psmux-theme-watch')
if (-not $mutex.WaitOne(0)) { exit 0 }   # da co ban khac dang chay
$script = Join-Path $env:USERPROFILE '.psmux-theme.cmd'
try {
    while ($true) {
        if (-not (Get-Process -Name psmux -ErrorAction SilentlyContinue)) { break }
        & $script 2>&1 | Out-Null
        Start-Sleep -Seconds 3
    }
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
