#requires -Version 5.1
<#
.SYNOPSIS
  Downloads the Vazirmatn font files used by the FeedbackFlow Flutter client.

.DESCRIPTION
  Pulls the official static TTF files from the Rastikerdar/vazirmatn release
  on GitHub and places them under assets/fonts so pubspec.yaml can register
  them. Re-running the script is safe; existing files are overwritten.
#>

[CmdletBinding()]
param(
    [string]$Version = "33.003",
    [string]$Destination = (Join-Path $PSScriptRoot "..\assets\fonts")
)

$ErrorActionPreference = "Stop"

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

$baseUrl = "https://github.com/rastikerdar/vazirmatn/releases/download/v$Version/Vazirmatn-fonts-static-v$Version.zip"
$tempZip = Join-Path $env:TEMP "vazirmatn-$Version.zip"
$tempDir = Join-Path $env:TEMP "vazirmatn-$Version"

Write-Host "Downloading Vazirmatn v$Version..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $baseUrl -OutFile $tempZip

if (Test-Path -LiteralPath $tempDir) {
    Remove-Item -Recurse -Force -LiteralPath $tempDir
}
Expand-Archive -LiteralPath $tempZip -DestinationPath $tempDir -Force

foreach ($weight in $weights) {
    $source = Get-ChildItem -Path $tempDir -Recurse `
        -Filter "Vazirmatn-$weight.ttf" | Select-Object -First 1
    if (-not $source) {
        Write-Warning "Vazirmatn-$weight.ttf not found in archive."
        continue
    }
    $target = Join-Path $Destination "Vazirmatn-$weight.ttf"
    Copy-Item -LiteralPath $source.FullName -Destination $target -Force
    Write-Host "  -> $target"
}

Remove-Item -LiteralPath $tempZip -Force
Remove-Item -LiteralPath $tempDir -Recurse -Force

Write-Host "Done." -ForegroundColor Green
