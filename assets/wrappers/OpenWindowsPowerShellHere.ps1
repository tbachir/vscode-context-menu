[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Path = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = (Get-Location).Path
}

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "The target path does not exist: $Path"
    return
}

Set-Location -LiteralPath $Path
Write-Host "Opened Windows PowerShell in: $Path"
