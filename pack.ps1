[CmdletBinding()]
param(
    [string]$Version   = '',
    [string]$StageDir  = '',
    [string]$OutputDir = '',
    [switch]$SkipBuild,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcDir    = Join-Path $ScriptDir 'openssl'

if (-not $Version) {
    if (-not (Test-Path (Join-Path $SrcDir '.git'))) {
        throw "Cannot auto-detect version: openssl submodule missing. Pass -Version X.Y.Z."
    }
    Push-Location $SrcDir
    try {
        $tag = git describe --tags --exact-match 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $tag) {
            $tag = git describe --tags 2>$null
        }
    }
    finally {
        Pop-Location
    }
    if (-not $tag) {
        throw "Could not determine version from submodule (no tags?). Pass -Version X.Y.Z."
    }
    $Version = $tag -replace '^openssl-', ''
}

if (-not $StageDir)  { $StageDir  = Join-Path $ScriptDir '.stage' }
if (-not $OutputDir) { $OutputDir = Join-Path $ScriptDir 'dist'   }

$StageDir  = [System.IO.Path]::GetFullPath($StageDir)
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)

$iscc = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
if (-not (Test-Path $iscc)) {
    $iscc = 'C:\Program Files\Inno Setup 6\ISCC.exe'
}
if (-not (Test-Path $iscc)) {
    $cmd = Get-Command iscc.exe -ErrorAction SilentlyContinue
    if ($cmd) { $iscc = $cmd.Source }
}
if (-not (Test-Path $iscc)) {
    throw 'ISCC.exe not found. Install Inno Setup 6 (e.g. choco install innosetup).'
}

Write-Host "Version:    $Version"
Write-Host "StageDir:   $StageDir"
Write-Host "OutputDir:  $OutputDir"
Write-Host "ISCC:       $iscc"
Write-Host ''

if (-not $SkipBuild) {
    Write-Host '== build.ps1 ==' -ForegroundColor Cyan
    & (Join-Path $ScriptDir 'build.ps1')
    if ($LASTEXITCODE -ne 0) { throw "build.ps1 failed (exit $LASTEXITCODE)" }
}

if (Test-Path $StageDir) {
    Write-Host "Clearing stage: $StageDir"
    Remove-Item -Recurse -Force $StageDir
}
New-Item -ItemType Directory -Path $StageDir | Out-Null

Write-Host '== install.ps1 -DestDir ==' -ForegroundColor Cyan
& (Join-Path $ScriptDir 'install.ps1') -DestDir $StageDir
if ($LASTEXITCODE -ne 0) { throw "install.ps1 failed (exit $LASTEXITCODE)" }

if (-not (Test-Path (Join-Path $StageDir 'Program Files\OpenSSL-Win64'))) {
    throw "Staged install incomplete: expected '$StageDir\Program Files\OpenSSL-Win64' to exist."
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
elseif ($Clean) {
    Write-Host "Clearing output: $OutputDir"
    Remove-Item -Force -Recurse "$OutputDir\*"
}

Write-Host '== iscc ==' -ForegroundColor Cyan
& $iscc `
    "/DVersion=$Version" `
    "/DStageRoot=$StageDir" `
    "/DOutputDir=$OutputDir" `
    "/DSourceRoot=$ScriptDir" `
    (Join-Path $ScriptDir 'installer.iss')
if ($LASTEXITCODE -ne 0) { throw "iscc failed (exit $LASTEXITCODE)" }

$setup = Join-Path $OutputDir "OpenSSL-Win64-$Version-setup.exe"
if (-not (Test-Path $setup)) {
    throw "Expected installer at $setup but it was not produced."
}

Write-Host ''
Write-Host "Installer: $setup" -ForegroundColor Green
Get-Item $setup | Select-Object Name, Length, LastWriteTime
