#requires -Version 5.1
<#
.SYNOPSIS
    Downloads the Vazirmatn font files used by the FeedbackFlow Flutter client.

.DESCRIPTION
    Pulls the official release archive from
    https://github.com/rastikerdar/vazirmatn/releases and copies the TTF
    weights referenced in pubspec.yaml under assets/fonts/.

    Re-running the script is safe; existing files are overwritten.
#>

[CmdletBinding()]
param(
    [string]$Version = "33.003",
    [string]$Destination
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Resolve script directory ourselves so it works whether the script is dot-
# sourced, run via -File, or invoked from a different cwd.
$scriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

if (-not $Destination) {
    $Destination = Join-Path $scriptDir "..\assets\fonts"
}

$weights = @(
    "Regular",
    "Medium",
    "SemiBold",
    "Bold",
    "ExtraBold",
    "Black"
)

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$url    = "https://github.com/rastikerdar/vazirmatn/releases/download/v$Version/vazirmatn-v$Version.zip"
$tmpZip = Join-Path $env:TEMP "vazirmatn-$Version.zip"
$tmpDir = Join-Path $env:TEMP "vazirmatn-$Version"

Write-Host "Downloading Vazirmatn v$Version..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $url -OutFile $tmpZip

if (Test-Path -LiteralPath $tmpDir) {
    Remove-Item -Recurse -Force -LiteralPath $tmpDir
}
Expand-Archive -LiteralPath $tmpZip -DestinationPath $tmpDir -Force

foreach ($weight in $weights) {
    $source = Get-ChildItem -Path $tmpDir -Recurse `
        -Filter "Vazirmatn-$weight.ttf" | Select-Object -First 1
    if (-not $source) {
        Write-Warning "Vazirmatn-$weight.ttf not found in archive."
        continue
    }
    $target = Join-Path $Destination "Vazirmatn-$weight.ttf"
    Copy-Item -LiteralPath $source.FullName -Destination $target -Force
    Write-Host "  -> $target"
}

Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Done." -ForegroundColor Green
