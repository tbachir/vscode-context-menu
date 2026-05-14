# Contributing

Contributions are welcome if they keep the project simple, auditable, and reversible.

## Principles

- Prefer per-user registry keys over machine-wide writes.
- Do not require administrator rights unless there is a clear reason.
- Do not hardcode personal paths.
- Keep install and uninstall paths symmetrical.
- Avoid compiled binaries.
- Make changes inspectable by non-experts.

## Local checks

On Windows, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Scripts.ps1
```

If PowerShell 7 is available, also run:

```powershell
pwsh.exe -NoProfile -File .\tests\Test-Scripts.ps1
```
