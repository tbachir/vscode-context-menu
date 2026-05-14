<#
.SYNOPSIS
Removes the "Open with VS Code" entries installed by this project.

.DESCRIPTION
Removes the context-menu registry keys from the selected scope. CurrentUser is
the default and does not require administrator rights.

.PARAMETER IncludeDrive
Whether to remove the drive context-menu entry too.

.PARAMETER Scope
Registry scope. Use the same scope that was used during installation.

.EXAMPLE
.\uninstall.ps1

.EXAMPLE
.\uninstall.ps1 -Scope LocalMachine
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [bool]$IncludeDrive = $true,

    [Parameter(Mandatory = $false)]
    [ValidateSet("CurrentUser", "LocalMachine")]
    [string]$Scope = "CurrentUser"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RegistryRoot {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [string]$SelectedScope
    )

    if ($SelectedScope -eq "LocalMachine") {
        return "Registry::HKEY_LOCAL_MACHINE\Software\Classes"
    }

    return "Registry::HKEY_CURRENT_USER\Software\Classes"
}

$registryRoot = Get-RegistryRoot -SelectedScope $Scope
$keys = @(
    "Directory\shell\OpenWithVSCode",
    "Directory\Background\shell\OpenWithVSCode"
)

if ($IncludeDrive) {
    $keys += "Drive\shell\OpenWithVSCode"
}

foreach ($relativeKey in $keys) {
    $fullPath = Join-Path $registryRoot $relativeKey
    if (Test-Path -LiteralPath $fullPath) {
        if ($PSCmdlet.ShouldProcess($fullPath, "Remove context-menu entry")) {
            Remove-Item -LiteralPath $fullPath -Recurse -Force
        }
    }
}

Write-Host "Removed Explorer context-menu entries from scope: $Scope" -ForegroundColor Green
