# Windows Dev Context Menu

Add useful developer actions to the Windows File Explorer context menu, per user and without requiring administrator rights.

It can add entries for:

- Open folder in Visual Studio Code
- Open folder in Windows Terminal
- Open Windows PowerShell here
- Open PowerShell 7 here, when `pwsh.exe` is installed
- Open Command Prompt here

The installer writes to `HKEY_CURRENT_USER\Software\Classes`, so it only affects the current Windows user.

## Why this exists

Windows context menu entries are often missing, duplicated, machine-specific, or tied to hardcoded paths. This project provides a clean, inspectable, reversible setup that works better for public reuse than a personal `.reg` file.

## Quick install

Download the repository, extract it, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DevContextMenu.ps1
```

Or double-click:

```text
install.cmd
```

By default, the installer proposes an interactive setup and detects the installed tools automatically.

## Recommended non-interactive install

Install VS Code, Windows Terminal, and Windows PowerShell entries:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DevContextMenu.ps1 -Components VSCode,WindowsTerminal,WindowsPowerShell -NonInteractive
```

Install every supported component that can be detected:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-DevContextMenu.ps1 -Components All -NonInteractive
```

## Uninstall

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Uninstall-DevContextMenu.ps1
```

Or double-click:

```text
uninstall.cmd
```

## What gets changed

Registry keys are created below:

```text
HKEY_CURRENT_USER\Software\Classes\Directory\shell\...
HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\...
HKEY_CURRENT_USER\Software\Classes\Drive\shell\...
```

Support wrapper files are installed below:

```text
%LOCALAPPDATA%\WindowsDevContextMenu
```

The wrappers are used for shell commands that need robust path handling, especially PowerShell folders containing spaces, quotes, apostrophes, accented characters, or other special characters.

## Windows 11 note

Classic registry-based shell entries may appear under **Show more options** in the modern Windows 11 context menu depending on your Windows build and Explorer configuration. This project intentionally uses the simple, auditable, per-user registry approach instead of a native shell extension.

## Components

| Component | Entry label | Detection |
| --- | --- | --- |
| `VSCode` | Open folder in VS Code | `Code.exe` in user/system install paths or `PATH` |
| `WindowsTerminal` | Open in Windows Terminal | `wt.exe` |
| `WindowsPowerShell` | Open Windows PowerShell here | Built-in Windows PowerShell |
| `PowerShell7` | Open PowerShell 7 here | `pwsh.exe` |
| `CommandPrompt` | Open Command Prompt here | `%ComSpec%` |
| `All` | All supported entries | Adds all detected components |

## Advanced options

```powershell
.\scripts\Install-DevContextMenu.ps1 -Help
```

Useful examples:

```powershell
# Install only VS Code and Windows Terminal
.\scripts\Install-DevContextMenu.ps1 -Components VSCode,WindowsTerminal -NonInteractive

# Use a custom VS Code executable path
.\scripts\Install-DevContextMenu.ps1 -Components VSCode -VSCodePath "C:\Tools\VSCode\Code.exe" -NonInteractive

# Put entries behind Shift + right-click only
.\scripts\Install-DevContextMenu.ps1 -Components All -ExtendedOnly -NonInteractive

# Avoid restarting Explorer automatically
.\scripts\Install-DevContextMenu.ps1 -Components All -SkipExplorerRestart -NonInteractive
```

## Direct `.reg` files

The `registry/` directory contains simple `.reg` files for inspection and minimal fallback use.

For real use, prefer the PowerShell installer because a `.reg` file cannot reliably detect whether VS Code, Windows Terminal, or PowerShell 7 were installed per-user, system-wide, or through a custom path.

## Security

Before running any script from the internet, inspect it. This project is intentionally small and avoids compiled binaries.

The installer does not require administrator rights, does not download dependencies, and only writes per-user registry entries plus local wrapper files.

## License

MIT. See [LICENSE](LICENSE).
