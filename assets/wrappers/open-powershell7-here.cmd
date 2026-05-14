@echo off
setlocal
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=%CD%"
if defined DEV_CONTEXT_MENU_PWSH_EXE (
  "%DEV_CONTEXT_MENU_PWSH_EXE%" -NoExit -NoProfile -File "%~dp0OpenPowerShell7Here.ps1" "%TARGET%"
) else (
  pwsh.exe -NoExit -NoProfile -File "%~dp0OpenPowerShell7Here.ps1" "%TARGET%"
)
