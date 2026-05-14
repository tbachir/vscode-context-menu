[CmdletBinding()]
param(
    [switch] $KeepSupportFiles,
    [switch] $SkipExplorerRestart,
    [switch] $NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectName = 'WindowsDevContextMenu'
$InstallRoot = Join-Path $env:LOCALAPPDATA $ProjectName
$EntryNames = @(
    'WindowsDevContextMenu.VSCode',
    'WindowsDevContextMenu.WindowsTerminal',
    'WindowsDevContextMenu.WindowsPowerShell',
    'WindowsDevContextMenu.PowerShell7',
    'WindowsDevContextMenu.CommandPrompt'
)

function Write-Step {
    param([string] $Message)
    Write-Host "[+] $Message"
}

function Write-Skip {
    param([string] $Message)
    Write-Host "[-] $Message"
}

function Remove-Entry {
    param([string] $Path)
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-Step "Removed: $Path"
    }
}

function Ask-YesNo {
    param([string] $Question, [bool] $Default = $true)

    if ($NonInteractive) { return $Default }

    $suffix = if ($Default) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = Read-Host "$Question $suffix"
        if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
        switch -Regex ($answer.Trim()) {
            '^(y|yes|o|oui)$' { return $true }
            '^(n|no|non)$' { return $false }
            default { Write-Host 'Please answer yes or no.' }
        }
    }
}

$basePaths = @(
    'HKCU:\Software\Classes\Directory\shell',
    'HKCU:\Software\Classes\Directory\Background\shell',
    'HKCU:\Software\Classes\Drive\shell'
)

foreach ($basePath in $basePaths) {
    foreach ($entryName in $EntryNames) {
        Remove-Entry -Path (Join-Path $basePath $entryName)
    }
}

[Environment]::SetEnvironmentVariable('DEV_CONTEXT_MENU_PWSH_EXE', $null, 'User')

if ($KeepSupportFiles) {
    Write-Skip "Keeping support files: $InstallRoot"
} elseif (Test-Path -LiteralPath $InstallRoot) {
    Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    Write-Step "Removed support files: $InstallRoot"
}

if ($SkipExplorerRestart) {
    Write-Skip 'Explorer restart skipped. You may need to restart File Explorer manually.'
} elseif (Ask-YesNo -Question 'Restart File Explorer now to refresh context menus?' -Default $true) {
    Write-Step 'Restarting File Explorer...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

Write-Step 'Done.'
