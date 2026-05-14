@echo off
setlocal
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=%CD%"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoExit -NoProfile -ExecutionPolicy Bypass -File "%~dp0OpenWindowsPowerShellHere.ps1" "%TARGET%"
