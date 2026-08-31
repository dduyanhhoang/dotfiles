# ~/.psmux-theme-watch.ps1 - theo doi theme Windows + muc pin, dong bo sang psmux.
# Chay nen, moi server psmux mot ban (mutex theo pid), tu thoat khi khong con psmux.
# pid server lay tu $env:TMUX (run-shell dat san) - goi nguoc psmux ngay luc
# khoi dong co the treo trong run-shell, nen khong lam the o day.
$srv = if ($env:TMUX -match 'psmux-(\d+)') { $matches[1] } else { 'none' }
$mutex = New-Object System.Threading.Mutex($false, "Local\psmux-theme-watch-$srv")
try {
    if (-not $mutex.WaitOne(0)) { exit 0 }        # server nay da co watcher
} catch [System.Threading.AbandonedMutexException] { }  # ban truoc bi kill -> minh nhan tiep
$script = Join-Path $env:USERPROFILE '.psmux-theme.cmd'

# Thanh pin kieu oh-my-tmux: 10 o, phan day mau do -> vang -> xanh, phan rong xam.
# psmux chi ap #[fg=..] viet thang trong file theme, khong ap cai den tu gia tri
# option -> mau nam trong .psmux-theme-*.conf, watcher chi gui ky tu tung o.
# Cung ly do do, so % duoc nhet vao dung 1 trong 10 o @bat_tN de an mau cua muc
# pin: N = so o dang day, nen 100% ra xanh va gan 0% ra do.
# Dung █/░ chu khong phai ◼/◻: U+25FB/FC ra font emoji nen bo qua mau fg.
$CELLS     = 10
$cellFull  = [string][char]0x2588   # █
$cellEmpty = [string][char]0x2591   # ░
$last = ''

try {
    while ($true) {
        if (-not (Get-Process -Name psmux -ErrorAction SilentlyContinue)) { break }
        & $script 2>&1 | Out-Null

        # rong het neu may khong co pin (desktop) -> segment bien mat
        # dat '@ten' trong nhay don: PowerShell coi @ten la splat neu de tran
        $b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        $pre = ''; $post = ''; $rest = ''; $n = 0; $slot = 0; $pct = ''
        if ($b -and $null -ne $b.EstimatedChargeRemaining) {
            $p = [int]$b.EstimatedChargeRemaining
            $n = [int][math]::Round($p * $CELLS / 100.0)
            $slot = [math]::Max(1, $n)          # 0% van co o mau do de hien so
            # BatteryStatus 2 = dang cam dien; nguoc lai la dang xa
            $pre  = "$(if ($b.BatteryStatus -eq 2) { [char]0x2191 } else { [char]0x2193 }) "
            $pct  = " $p%"
            $post = ' | '
            $rest = $cellEmpty * ($CELLS - $n)
        }
        if ("$pre|$n|$pct" -ne $last) {
            $last = "$pre|$n|$pct"
            psmux set -g '@bat_pre'  "$pre"  2>&1 | Out-Null
            psmux set -g '@bat_rest' "$rest" 2>&1 | Out-Null
            psmux set -g '@bat_post' "$post" 2>&1 | Out-Null
            foreach ($i in 1..$CELLS) {
                psmux set -g "@bat_c$i" "$(if ($i -le $n)    { $cellFull } else { '' })" 2>&1 | Out-Null
                psmux set -g "@bat_t$i" "$(if ($i -eq $slot) { $pct }      else { '' })" 2>&1 | Out-Null
            }
        }

        Start-Sleep -Seconds 3
    }
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
