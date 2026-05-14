@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Uninstall-DevContextMenu.ps1" %*
set EXIT_CODE=%ERRORLEVEL%
echo.
if not "%EXIT_CODE%"=="0" (
  echo Uninstall failed with exit code %EXIT_CODE%.
) else (
  echo Uninstall completed.
)
pause
exit /b %EXIT_CODE%
