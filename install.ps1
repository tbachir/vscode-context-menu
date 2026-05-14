<#
.SYNOPSIS
Adds an "Open with VS Code" entry to the Windows File Explorer context menu.

.DESCRIPTION
This script installs per-user context-menu entries by default. It detects the
Visual Studio Code executable from common installation locations or from PATH.
No administrator rights are required for the default CurrentUser scope.

.PARAMETER CodePath
Optional explicit path to Code.exe.

.PARAMETER Label
Menu label displayed in File Explorer.

.PARAMETER IncludeDrive
Whether to add the entry when right-clicking a drive.

.PARAMETER Scope
Registry scope. CurrentUser is recommended. LocalMachine requires elevation.

.EXAMPLE
.\install.ps1

.EXAMPLE
.\install.ps1 -CodePath "C:\Program Files\Microsoft VS Code\Code.exe"

.EXAMPLE
.\install.ps1 -Label "Open Folder as VS Code Project" -IncludeDrive:$false
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$CodePath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Label = "Open with VS Code",

    [Parameter(Mandatory = $false)]
    [bool]$IncludeDrive = $true,

    [Parameter(Mandatory = $false)]
    [ValidateSet("CurrentUser", "LocalMachine")]
    [string]$Scope = "CurrentUser"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-CodePath {
    param(
        [Parameter(Mandatory = $false)]
        [string]$ExplicitPath
    )

    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $candidates.Add($ExplicitPath)
    }

    foreach ($commandName in @("code.cmd", "code")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
            if ($command.Source -match "\\bin\\code(\.cmd)?$") {
                $possibleExe = Join-Path (Split-Path (Split-Path $command.Source -Parent) -Parent) "Code.exe"
                $candidates.Add($possibleExe)
            }

            $candidates.Add($command.Source)
        }
    }

    $commonPaths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\Code.exe"),
        (Join-Path $env:ProgramFiles "Microsoft VS Code\Code.exe")
    )

    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $commonPaths += (Join-Path $programFilesX86 "Microsoft VS Code\Code.exe")
    }

    foreach ($path in $commonPaths) {
        $candidates.Add($path)
    }

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        if (Test-Path -LiteralPath $expanded -PathType Leaf) {
            return (Resolve-Path -LiteralPath $expanded).Path
        }
    }

    throw "Could not find Code.exe. Install Visual Studio Code or pass -CodePath 'C:\Path\To\Code.exe'."
}

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

function Set-ContextMenuEntry {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativeKey,

        [Parameter(Mandatory = $true)]
        [string]$MenuLabel,

        [Parameter(Mandatory = $true)]
        [string]$ExecutablePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetToken
    )

    $shellKey = Join-Path $Root $RelativeKey
    $commandKey = Join-Path $shellKey "command"
    $command = "`"$ExecutablePath`" --reuse-window `"$TargetToken`""
    $icon = "`"$ExecutablePath`",0"

    if ($PSCmdlet.ShouldProcess($shellKey, "Create or update context-menu entry")) {
        New-Item -Path $shellKey -Force | Out-Null
        New-Item -Path $commandKey -Force | Out-Null

        Set-Item -Path $shellKey -Value $MenuLabel
        New-ItemProperty -Path $shellKey -Name "MUIVerb" -Value $MenuLabel -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $shellKey -Name "Icon" -Value $icon -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $shellKey -Name "Position" -Value "Top" -PropertyType String -Force | Out-Null

        Set-Item -Path $commandKey -Value $command
    }
}

$resolvedCodePath = Resolve-CodePath -ExplicitPath $CodePath
$registryRoot = Get-RegistryRoot -SelectedScope $Scope

$entries = @(
    @{ Key = "Directory\shell\OpenWithVSCode"; Token = "%1" },
    @{ Key = "Directory\Background\shell\OpenWithVSCode"; Token = "%V" }
)

if ($IncludeDrive) {
    $entries += @{ Key = "Drive\shell\OpenWithVSCode"; Token = "%1" }
}

foreach ($entry in $entries) {
    Set-ContextMenuEntry `
        -Root $registryRoot `
        -RelativeKey $entry.Key `
        -MenuLabel $Label `
        -ExecutablePath $resolvedCodePath `
        -TargetToken $entry.Token
}

Write-Host "Installed Explorer context-menu entries." -ForegroundColor Green
Write-Host "Scope: $Scope"
Write-Host "VS Code: $resolvedCodePath"
Write-Host "Label: $Label"
Write-Host "Drive entry: $IncludeDrive"
