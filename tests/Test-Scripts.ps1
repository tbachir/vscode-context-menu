[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'README.md',
    'LICENSE',
    'scripts\Install-DevContextMenu.ps1',
    'scripts\Uninstall-DevContextMenu.ps1',
    'assets\wrappers\OpenWindowsPowerShellHere.ps1',
    'assets\wrappers\OpenPowerShell7Here.ps1',
    'assets\wrappers\open-windows-powershell-here.cmd',
    'assets\wrappers\open-powershell7-here.cmd'
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $relativePath"
    }
}

$psFiles = Get-ChildItem -Path $root -Filter '*.ps1' -Recurse
foreach ($file in $psFiles) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref] $tokens, [ref] $errors) | Out-Null
    if ($errors.Count -gt 0) {
        throw "PowerShell parse errors in $($file.FullName): $($errors | Out-String)"
    }
}

$forbiddenPatterns = @(
    'C:\\Users\\'
)

$filesToScan = Get-ChildItem -Path $root -File -Recurse
foreach ($file in $filesToScan) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $forbiddenPatterns) {
        if ($content -match $pattern) {
            throw "Forbidden personal pattern '$pattern' found in $($file.FullName)"
        }
    }
}

Write-Host 'All checks passed.'
