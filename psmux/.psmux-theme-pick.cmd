@echo off
rem ~/.psmux-theme-pick.cmd - chon theme roi CHEP ra .psmux-theme-active.conf.
rem Khong goi psmux: run-shell cua psmux truyen sai TMUX nen moi lenh psmux tu
rem script deu roi vao server dau tien. Config tu source-file file nay lay ->
rem luon dung server dang khoi dong.
setlocal
set "STATE=%USERPROFILE%\.psmux-theme.state"

set "CUR="
if exist "%STATE%" set /p CUR=<"%STATE%"
if "%CUR%"=="pin:light" set "THEME=light" & goto :copy
if "%CUR%"=="pin:dark"  set "THEME=dark"  & goto :copy

rem AppsUseLightTheme: 0x1 = light, 0x0 = dark. Thieu key thi coi nhu dark.
set "RAW="
for /f "tokens=3" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme 2^>nul') do set "RAW=%%a"
if "%RAW%"=="0x1" (set "THEME=light") else (set "THEME=dark")

:copy
copy /y "%USERPROFILE%\.psmux-theme-%THEME%.conf" "%USERPROFILE%\.psmux-theme-active.conf" >nul
exit /b 0
