@echo off
rem ~/.psmux-theme.cmd - dong bo theme psmux voi dark/light mode cua Windows
rem   .psmux-theme.cmd          che do tu dong (watcher goi): doi thi moi ap,
rem                             va ton trong ghim do nguoi dung dat
rem   .psmux-theme.cmd sync     bo ghim roi ap theo registry  (prefix + T)
rem   .psmux-theme.cmd light    ep theme sang va ghim         (prefix + M-l)
rem   .psmux-theme.cmd dark     ep theme toi va ghim          (prefix + M-d)
setlocal
set "STATE=%USERPROFILE%\.psmux-theme.state"
set "ARG=%~1"

if /i "%ARG%"=="light" goto :force
if /i "%ARG%"=="dark"  goto :force

rem AppsUseLightTheme: 0x1 = light, 0x0 = dark. Thieu key thi coi nhu dark.
set "RAW="
for /f "tokens=3" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme 2^>nul') do set "RAW=%%a"
if "%RAW%"=="0x1" (set "THEME=light") else (set "THEME=dark")

set "CUR="
if exist "%STATE%" set /p CUR=<"%STATE%"

if /i "%ARG%"=="sync" goto :apply

rem tu dong: dang ghim thi khong dung toi; khong doi thi khong lam gi ca
if "%CUR%"=="pin:light" exit /b 0
if "%CUR%"=="pin:dark"  exit /b 0
if "%CUR%"=="%THEME%"   exit /b 0

:apply
psmux source-file "%USERPROFILE%\.psmux-theme-%THEME%.conf"
psmux source-file "%USERPROFILE%\.psmux-binds.conf"
> "%STATE%" echo %THEME%
psmux display-message "psmux theme: %THEME%"
exit /b 0

:force
psmux source-file "%USERPROFILE%\.psmux-theme-%ARG%.conf"
psmux source-file "%USERPROFILE%\.psmux-binds.conf"
> "%STATE%" echo pin:%ARG%
psmux display-message "psmux theme: %ARG% [ghim] - prefix+T de bo ghim"
exit /b 0
