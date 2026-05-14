# Contributing

Contributions are welcome if they keep the project small, readable, and safe.

## Guidelines

- Keep the default installation under `HKEY_CURRENT_USER`.
- Do not introduce remote downloads in install scripts.
- Do not bundle third-party binaries.
- Keep scripts readable and auditable.
- Include an uninstall path for any new registry keys.

## Local validation

From PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1 -WhatIf
Set-ExecutionPolicy -Scope Process Bypass -Force; .\uninstall.ps1 -WhatIf
```

For a disposable test environment, run the installer and then the uninstaller.
