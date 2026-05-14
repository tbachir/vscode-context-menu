[CmdletBinding()]
param(
    [ValidateSet('VSCode', 'WindowsTerminal', 'WindowsPowerShell', 'PowerShell7', 'CommandPrompt', 'All')]
    [string[]] $Components = @(),

    [string] $VSCodePath,
    [string] $WindowsTerminalPath,
    [string] $PowerShell7Path,

    [switch] $NonInteractive,
    [switch] $ExtendedOnly,
    [switch] $SkipExplorerRestart,
    [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectName = 'WindowsDevContextMenu'
$InstallRoot = Join-Path $env:LOCALAPPDATA $ProjectName
$WrapperRoot = Join-Path $InstallRoot 'wrappers'

function Show-Help {
    @"
Windows Dev Context Menu installer

Usage:
  .\scripts\Install-DevContextMenu.ps1
  .\scripts\Install-DevContextMenu.ps1 -Components VSCode,WindowsTerminal,WindowsPowerShell -NonInteractive
  .\scripts\Install-DevContextMenu.ps1 -Components All -NonInteractive

Components:
  VSCode              Open folder in VS Code
  WindowsTerminal    Open in Windows Terminal
  WindowsPowerShell  Open Windows PowerShell here
  PowerShell7        Open PowerShell 7 here, if pwsh.exe exists
  CommandPrompt      Open Command Prompt here
  All                All supported detected components

Options:
  -VSCodePath <path>             Custom Code.exe path
  -WindowsTerminalPath <path>    Custom wt.exe path
  -PowerShell7Path <path>        Custom pwsh.exe path
  -NonInteractive                Do not ask questions
  -ExtendedOnly                  Show entries only on Shift + right-click
  -SkipExplorerRestart           Do not restart Explorer after installation
  -Help                          Show this help
"@ | Write-Host
}

function Test-IsWindows {
    if ($PSVersionTable.PSEdition -eq 'Core') {
        return $IsWindows
    }
    return $true
}

function Write-Step {
    param([string] $Message)
    Write-Host "[+] $Message"
}

function Write-Skip {
    param([string] $Message)
    Write-Host "[-] $Message"
}

function Get-ExistingFile {
    param([string[]] $Candidates)

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        if (Test-Path -LiteralPath $expanded -PathType Leaf) {
            return (Resolve-Path -LiteralPath $expanded).Path
        }
    }

    return $null
}

function Get-CommandPath {
    param([string] $Name)

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $cmd) { return $null }

    if ($cmd.Source -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $cmd.Source).Path
    }

    if ($cmd.Path -and (Test-Path -LiteralPath $cmd.Path -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $cmd.Path).Path
    }

    return $Name
}

function Resolve-VSCodePath {
    if ($VSCodePath) {
        if (-not (Test-Path -LiteralPath $VSCodePath -PathType Leaf)) {
            throw "VS Code executable not found at: $VSCodePath"
        }
        return (Resolve-Path -LiteralPath $VSCodePath).Path
    }

    $fromCommand = Get-CommandPath -Name 'Code.exe'
    if ($fromCommand) { return $fromCommand }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\Code.exe')
    )

    return Get-ExistingFile -Candidates $candidates
}

function Resolve-WindowsTerminalPath {
    if ($WindowsTerminalPath) {
        if (-not (Test-Path -LiteralPath $WindowsTerminalPath -PathType Leaf)) {
            throw "Windows Terminal executable not found at: $WindowsTerminalPath"
        }
        return (Resolve-Path -LiteralPath $WindowsTerminalPath).Path
    }

    $fromCommand = Get-CommandPath -Name 'wt.exe'
    if ($fromCommand) { return $fromCommand }

    $candidate = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wt.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }

    return $null
}

function Resolve-WindowsPowerShellPath {
    $candidate = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    return Get-CommandPath -Name 'powershell.exe'
}

function Resolve-PowerShell7Path {
    if ($PowerShell7Path) {
        if (-not (Test-Path -LiteralPath $PowerShell7Path -PathType Leaf)) {
            throw "PowerShell 7 executable not found at: $PowerShell7Path"
        }
        return (Resolve-Path -LiteralPath $PowerShell7Path).Path
    }

    return Get-CommandPath -Name 'pwsh.exe'
}

function Resolve-CmdPath {
    if ($env:ComSpec -and (Test-Path -LiteralPath $env:ComSpec -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $env:ComSpec).Path
    }
    return Get-CommandPath -Name 'cmd.exe'
}

function ConvertTo-RegistryCommand {
    param([string] $Executable, [string[]] $Arguments)

    $quotedExecutable = '"' + $Executable.Replace('"', '\"') + '"'
    if (-not $Arguments -or $Arguments.Count -eq 0) {
        return $quotedExecutable
    }

    return ($quotedExecutable + ' ' + ($Arguments -join ' '))
}

function Set-DefaultValue {
    param([string] $Path, [string] $Value)

    # Use the PowerShell Registry provider instead of calling
    # Microsoft.Win32.RegistryKey default-value API directly. On some systems,
    # Get-Item can return a RegistryKey handle that is not opened for write
    # access, which raises "Unable to write to the registry key" even under
    # HKCU. Set-Item writes the unnamed/default value through the provider and
    # stays admin-free.
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    Set-Item -LiteralPath $Path -Value $Value
}

function New-MenuEntry {
    param(
        [string] $RegistryPath,
        [string] $Label,
        [string] $Icon,
        [string] $Command
    )

    $commandPath = Join-Path $RegistryPath 'command'
    New-Item -Path $RegistryPath -Force | Out-Null
    New-Item -Path $commandPath -Force | Out-Null

    Set-DefaultValue -Path $RegistryPath -Value $Label
    if ($Icon) {
        Set-ItemProperty -LiteralPath $RegistryPath -Name 'Icon' -Value $Icon
    }

    if ($ExtendedOnly) {
        New-ItemProperty -LiteralPath $RegistryPath -Name 'Extended' -Value '' -PropertyType String -Force | Out-Null
    } else {
        Remove-ItemProperty -LiteralPath $RegistryPath -Name 'Extended' -ErrorAction SilentlyContinue
    }

    Set-DefaultValue -Path $commandPath -Value $Command
}

function New-ContextEntries {
    param(
        [string] $Name,
        [string] $FolderLabel,
        [string] $BackgroundLabel,
        [string] $DriveLabel,
        [string] $Icon,
        [string] $FolderCommand,
        [string] $BackgroundCommand,
        [string] $DriveCommand
    )

    $base = 'HKCU:\Software\Classes'
    New-MenuEntry -RegistryPath (Join-Path $base "Directory\shell\$Name") -Label $FolderLabel -Icon $Icon -Command $FolderCommand
    New-MenuEntry -RegistryPath (Join-Path $base "Directory\Background\shell\$Name") -Label $BackgroundLabel -Icon $Icon -Command $BackgroundCommand
    New-MenuEntry -RegistryPath (Join-Path $base "Drive\shell\$Name") -Label $DriveLabel -Icon $Icon -Command $DriveCommand
}

function Install-Wrappers {
    $sourceRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\wrappers'
    New-Item -ItemType Directory -Path $WrapperRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceRoot '*') -Destination $WrapperRoot -Force
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

function Get-SelectedComponents {
    $availableComponents = @('VSCode', 'WindowsTerminal', 'WindowsPowerShell', 'PowerShell7', 'CommandPrompt')

    if ($Components -contains 'All') {
        return $availableComponents
    }

    if ($Components.Count -gt 0) {
        return $Components
    }

    if ($NonInteractive) {
        return @('VSCode', 'WindowsTerminal', 'WindowsPowerShell')
    }

    Write-Host 'Select entries to install:'
    $selected = New-Object System.Collections.Generic.List[string]

    foreach ($component in $availableComponents) {
        $default = $component -in @('VSCode', 'WindowsTerminal', 'WindowsPowerShell')
        if (Ask-YesNo -Question "Install $component?" -Default $default) {
            $selected.Add($component) | Out-Null
        }
    }

    return $selected.ToArray()
}

function Restart-ExplorerIfRequested {
    if ($SkipExplorerRestart) {
        Write-Skip 'Explorer restart skipped. You may need to restart File Explorer manually.'
        return
    }

    if (Ask-YesNo -Question 'Restart File Explorer now to refresh context menus?' -Default $true) {
        Write-Step 'Restarting File Explorer...'
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    } else {
        Write-Skip 'Explorer restart skipped. You may need to restart File Explorer manually.'
    }
}

if ($Help) {
    Show-Help
    exit 0
}

if (-not (Test-IsWindows)) {
    throw 'This installer only supports Windows.'
}

Write-Step "Installing support files to: $InstallRoot"
Install-Wrappers

$selectedComponents = @(Get-SelectedComponents)
if ($selectedComponents.Count -eq 0) {
    Write-Skip 'No components selected.'
    exit 0
}

if ($selectedComponents -contains 'VSCode') {
    $codePath = Resolve-VSCodePath
    if ($codePath) {
        Write-Step "Adding VS Code entries using: $codePath"
        $icon = "$codePath,0"
        New-ContextEntries -Name 'WindowsDevContextMenu.VSCode' `
            -FolderLabel 'Open folder in VS Code' `
            -BackgroundLabel 'Open folder in VS Code' `
            -DriveLabel 'Open drive in VS Code' `
            -Icon $icon `
            -FolderCommand (ConvertTo-RegistryCommand -Executable $codePath -Arguments @('"%1"')) `
            -BackgroundCommand (ConvertTo-RegistryCommand -Executable $codePath -Arguments @('"%V"')) `
            -DriveCommand (ConvertTo-RegistryCommand -Executable $codePath -Arguments @('"%1"'))
    } else {
        Write-Skip 'VS Code was selected but Code.exe could not be found.'
    }
}

if ($selectedComponents -contains 'WindowsTerminal') {
    $wtPath = Resolve-WindowsTerminalPath
    if ($wtPath) {
        Write-Step "Adding Windows Terminal entries using: $wtPath"
        $icon = "$wtPath,0"
        New-ContextEntries -Name 'WindowsDevContextMenu.WindowsTerminal' `
            -FolderLabel 'Open in Windows Terminal' `
            -BackgroundLabel 'Open in Windows Terminal' `
            -DriveLabel 'Open drive in Windows Terminal' `
            -Icon $icon `
            -FolderCommand (ConvertTo-RegistryCommand -Executable $wtPath -Arguments @('-d', '"%1"')) `
            -BackgroundCommand (ConvertTo-RegistryCommand -Executable $wtPath -Arguments @('-d', '"%V"')) `
            -DriveCommand (ConvertTo-RegistryCommand -Executable $wtPath -Arguments @('-d', '"%1"'))
    } else {
        Write-Skip 'Windows Terminal was selected but wt.exe could not be found.'
    }
}

if ($selectedComponents -contains 'WindowsPowerShell') {
    $psPath = Resolve-WindowsPowerShellPath
    $script = Join-Path $WrapperRoot 'OpenWindowsPowerShellHere.ps1'
    if ($psPath -and (Test-Path -LiteralPath $script -PathType Leaf)) {
        Write-Step "Adding Windows PowerShell entries using: $psPath"
        $icon = "$psPath,0"
        New-ContextEntries -Name 'WindowsDevContextMenu.WindowsPowerShell' `
            -FolderLabel 'Open Windows PowerShell here' `
            -BackgroundLabel 'Open Windows PowerShell here' `
            -DriveLabel 'Open Windows PowerShell here' `
            -Icon $icon `
            -FolderCommand (ConvertTo-RegistryCommand -Executable $psPath -Arguments @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $script + '"'), '"%1"')) `
            -BackgroundCommand (ConvertTo-RegistryCommand -Executable $psPath -Arguments @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $script + '"'), '"%V"')) `
            -DriveCommand (ConvertTo-RegistryCommand -Executable $psPath -Arguments @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $script + '"'), '"%1"'))
    } else {
        Write-Skip 'Windows PowerShell was selected but powershell.exe or its support script could not be found.'
    }
}

if ($selectedComponents -contains 'PowerShell7') {
    $pwshPath = Resolve-PowerShell7Path
    $script = Join-Path $WrapperRoot 'OpenPowerShell7Here.ps1'
    if ($pwshPath -and (Test-Path -LiteralPath $script -PathType Leaf)) {
        Write-Step "Adding PowerShell 7 entries using: $pwshPath"
        $icon = "$pwshPath,0"
        New-ContextEntries -Name 'WindowsDevContextMenu.PowerShell7' `
            -FolderLabel 'Open PowerShell 7 here' `
            -BackgroundLabel 'Open PowerShell 7 here' `
            -DriveLabel 'Open PowerShell 7 here' `
            -Icon $icon `
            -FolderCommand (ConvertTo-RegistryCommand -Executable $pwshPath -Arguments @('-NoExit', '-NoProfile', '-File', ('"' + $script + '"'), '"%1"')) `
            -BackgroundCommand (ConvertTo-RegistryCommand -Executable $pwshPath -Arguments @('-NoExit', '-NoProfile', '-File', ('"' + $script + '"'), '"%V"')) `
            -DriveCommand (ConvertTo-RegistryCommand -Executable $pwshPath -Arguments @('-NoExit', '-NoProfile', '-File', ('"' + $script + '"'), '"%1"'))
    } else {
        Write-Skip 'PowerShell 7 was selected but pwsh.exe or its support script could not be found.'
    }
}

if ($selectedComponents -contains 'CommandPrompt') {
    $cmdPath = Resolve-CmdPath
    if ($cmdPath) {
        Write-Step "Adding Command Prompt entries using: $cmdPath"
        $icon = "$cmdPath,0"
        New-ContextEntries -Name 'WindowsDevContextMenu.CommandPrompt' `
            -FolderLabel 'Open Command Prompt here' `
            -BackgroundLabel 'Open Command Prompt here' `
            -DriveLabel 'Open Command Prompt here' `
            -Icon $icon `
            -FolderCommand (ConvertTo-RegistryCommand -Executable $cmdPath -Arguments @('/s', '/k', 'pushd', '"%1"')) `
            -BackgroundCommand (ConvertTo-RegistryCommand -Executable $cmdPath -Arguments @('/s', '/k', 'pushd', '"%V"')) `
            -DriveCommand (ConvertTo-RegistryCommand -Executable $cmdPath -Arguments @('/s', '/k', 'pushd', '"%1"'))
    } else {
        Write-Skip 'Command Prompt was selected but cmd.exe could not be found.'
    }
}

Restart-ExplorerIfRequested
Write-Step 'Done.'
