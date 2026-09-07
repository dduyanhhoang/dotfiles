# ~/.psmux-battery-watch.ps1 - day muc pin vao thanh status cua psmux.
# Chay nen, mot ban duy nhat cho ca may (mutex), tu thoat khi khong con psmux nao.
#
# psmux dung MOT SERVER CHO MOI SESSION (~/.psmux/<ten>.pid|.port), va lenh psmux
# tu script chi noi chuyen voi server "hien tai" -> cua so moi = server moi =
# khong co @bat_*. Nen watcher tu liet ke server dang song va day option vao
# tung cai, chon server bang $env:PSMUX_SESSION.
$mutex = New-Object System.Threading.Mutex($false, 'Local\psmux-battery-watch')
try {
    if (-not $mutex.WaitOne(0)) { exit 0 }        # da co ban khac dang chay
} catch [System.Threading.AbandonedMutexException] { }  # ban truoc bi kill -> minh nhan tiep
$psmuxRt = Join-Path $env:USERPROFILE '.psmux'

# $env:TMUX thang the PSMUX_SESSION khi chon server, ma run-shell lai truyen
# TMUX cua server dau tien -> xoa di, neu khong moi lenh deu roi vao server do.
$env:TMUX = $null
$env:TMUX_PANE = $null

# Thanh pin kieu oh-my-tmux: 10 o, mau xanh nhat dan theo muc pin, phan rong xam.
# psmux chi ap #[fg=..] viet thang trong file theme, khong ap cai den tu gia tri
# option -> mau nam trong .psmux-theme.conf, watcher chi gui ky tu tung o.
# Cung ly do do, so % duoc nhet vao dung 1 trong 10 o @bat_tN de an mau cua muc
# pin: N = so o dang day.
# Dung █/░ chu khong phai ◼/◻: U+25FB/FC ra font emoji nen bo qua mau fg.
$CELLS     = 10
$cellFull  = [string][char]0x2588   # █
$cellEmpty = [string][char]0x2591   # ░
$last = ''

# Ten cac session con server song. Khong dat bien ten $pid: trung bien tu dong
# cua PowerShell (pid tien trinh hien tai).
function Get-LiveSessions {
    Get-ChildItem (Join-Path $psmuxRt '*.pid') -ErrorAction SilentlyContinue | ForEach-Object {
        $spid = ((Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -split ':')[0].Trim()
        if ($spid -and (Get-Process -Id $spid -ErrorAction SilentlyContinue)) { $_.BaseName }
    }
}

try {
    while ($true) {
        $sessions = @(Get-LiveSessions)
        if (-not $sessions) { break }

        # rong het neu may khong co pin (desktop) -> segment bien mat
        # dat '@ten' trong nhay don: PowerShell coi @ten la splat neu de tran
        $b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        $pre = ''; $post = ''; $rest = ''; $n = 0; $slot = 0; $pct = ''
        if ($b -and $null -ne $b.EstimatedChargeRemaining) {
            $p = [int]$b.EstimatedChargeRemaining
            $n = [int][math]::Round($p * $CELLS / 100.0)
            $slot = [math]::Max(1, $n)          # 0% van co o de hien so
            # BatteryStatus 2 = dang cam dien; nguoc lai la dang xa
            $pre  = "$(if ($b.BatteryStatus -eq 2) { [char]0x2191 } else { [char]0x2193 }) "
            $pct  = " $p%"
            $post = ' | '
            $rest = $cellEmpty * ($CELLS - $n)
        }

        # day lai khi pin doi HOAC khi co server moi xuat hien
        $key = "$pre|$n|$pct|" + (($sessions | Sort-Object) -join ',')
        if ($key -ne $last) {
            $last = $key
            foreach ($s in $sessions) {
                $env:PSMUX_SESSION = $s
                psmux set -g '@bat_pre'  "$pre"  2>&1 | Out-Null
                psmux set -g '@bat_rest' "$rest" 2>&1 | Out-Null
                psmux set -g '@bat_post' "$post" 2>&1 | Out-Null
                foreach ($i in 1..$CELLS) {
                    psmux set -g "@bat_c$i" "$(if ($i -le $n)    { $cellFull } else { '' })" 2>&1 | Out-Null
                    psmux set -g "@bat_t$i" "$(if ($i -eq $slot) { $pct }      else { '' })" 2>&1 | Out-Null
                }
            }
        }

        Start-Sleep -Seconds 3
    }
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
