# Security Policy

## Supported versions

Only the latest release is supported.

## Reporting a vulnerability

Please open a GitHub security advisory or a private issue if the repository host supports it.

## Scope

This project writes per-user Windows registry entries and local support wrapper files. It should not request administrator rights, download remote code, or modify system-wide registry hives.

## Safe usage checklist

Before running the installer:

1. Inspect `scripts/Install-DevContextMenu.ps1`.
2. Confirm it writes to `HKEY_CURRENT_USER\Software\Classes`.
3. Confirm it does not download or execute remote content.
4. Run the uninstall script if you want to remove all entries.
