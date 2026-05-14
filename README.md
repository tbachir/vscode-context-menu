# VS Code Context Menu for Windows

Add a clean **Open with VS Code** entry to the Windows File Explorer context menu.

This repository provides a small, transparent, user-scoped setup for opening folders directly in Visual Studio Code from File Explorer.

## What it adds

- Right-click **on a folder** → `Open with VS Code`
- Right-click **inside a folder background** → `Open with VS Code`
- Right-click **on a drive** → `Open with VS Code`
- Installs under `HKEY_CURRENT_USER`, so administrator rights are not required
- Includes uninstall scripts and registry removal files

On Windows 11, this entry may appear under **Show more options** depending on the system context-menu behavior.

## Recommended install

Download or clone the repository, then run PowerShell from the project folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1
```

The installer auto-detects VS Code from common locations:

- User install: `%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe`
- System install: `%ProgramFiles%\Microsoft VS Code\Code.exe`
- 32-bit system install: `%ProgramFiles(x86)%\Microsoft VS Code\Code.exe`
- `code` / `code.cmd` if available in `PATH`

You can also provide the path manually:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1 -CodePath "C:\Path\To\Code.exe"
```

## Direct `.reg` install

For a default per-user VS Code installation, you can import:

```text
registry\install-current-user-default-vscode.reg
```

This registry file is anonymous and uses `%LOCALAPPDATA%` rather than a hard-coded username. The PowerShell installer remains the safest option because it writes the exact detected path.

## Uninstall

Recommended:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\uninstall.ps1
```

Or import:

```text
registry\uninstall-current-user.reg
```

## Batch shortcuts

For convenience, double-clickable wrappers are also included:

- `install-current-user.cmd`
- `uninstall-current-user.cmd`

If Windows blocks downloaded scripts, right-click the file, open **Properties**, then choose **Unblock**.

## Advanced options

Install without the drive context-menu entry:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1 -IncludeDrive:$false
```

Customize the menu label:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1 -Label "Open Folder as VS Code Project"
```

Install machine-wide instead of current-user only:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1 -Scope LocalMachine
```

Machine-wide installation writes to `HKLM:\Software\Classes` and usually requires an elevated PowerShell session.

## How it works

The installer creates these registry keys:

```text
HKCU\Software\Classes\Directory\shell\OpenWithVSCode
HKCU\Software\Classes\Directory\Background\shell\OpenWithVSCode
HKCU\Software\Classes\Drive\shell\OpenWithVSCode
```

Each key points to `Code.exe` with `--reuse-window` and passes the selected folder path to VS Code.

## Compatibility

Tested design target:

- Windows 10
- Windows 11
- Visual Studio Code user or system installation

This project does not install VS Code. It only adds or removes Explorer context-menu entries.

## Security

The scripts only modify Explorer context-menu registry keys under the selected scope. No telemetry, no external downloads, no background services.

Review the files before running them. They are intentionally small and readable.

## License

MIT. See [LICENSE](LICENSE).
