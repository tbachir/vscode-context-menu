[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$requiredFiles = @(
    "README.md",
    "LICENSE",
    "install.ps1",
    "uninstall.ps1",
    "registry\install-current-user-default-vscode.reg",
    "registry\uninstall-current-user.reg"
)

foreach ($relative in $requiredFiles) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required file: $relative"
    }
}

foreach ($script in @("install.ps1", "uninstall.ps1")) {
    $path = Join-Path $root $script
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        throw "PowerShell parse errors in $script: $($errors | Out-String)"
    }
}

Write-Host "Repository validation passed." -ForegroundColor Green
