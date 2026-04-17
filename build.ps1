[CmdletBinding()]
param(
    [string]$InstallPrefix = 'C:\Program Files\OpenSSL-Win64',
    [string]$OpenSSLDir    = 'C:\Program Files\Common Files\SSL',
    [string]$Target        = 'VC-WIN64A',
    [switch]$SkipTests,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcDir    = Join-Path $ScriptDir 'openssl'

if (-not (Test-Path (Join-Path $SrcDir 'Configure'))) {
    throw "OpenSSL source not found at $SrcDir. Run: git submodule update --init"
}

$required = @('perl.exe', 'nasm.exe', 'cl.exe', 'nmake.exe', 'link.exe')
$missing  = @()
foreach ($t in $required) {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { $missing += $t }
}
if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host "Missing on PATH: $($missing -join ', ')" -ForegroundColor Red
    Write-Host ''
    Write-Host 'Prerequisites:'
    Write-Host "  cl.exe / nmake.exe / link.exe  -> launch from 'x64 Native Tools Command Prompt for VS 2022'"
    Write-Host "  perl.exe                       -> add the perl\bin subdirectory of your Strawberry Perl install to PATH"
    Write-Host '  nasm.exe                       -> add the folder containing nasm.exe to PATH'
    throw 'Toolchain incomplete'
}

Write-Host "Source:        $SrcDir"
Write-Host "Target:        $Target"
Write-Host "InstallPrefix: $InstallPrefix"
Write-Host "OpenSSLDir:    $OpenSSLDir"
Write-Host ''

Push-Location $SrcDir
try {
    if ($Clean -and (Test-Path 'makefile')) {
        Write-Host '== nmake clean ==' -ForegroundColor Cyan
        & nmake clean
    }

    Write-Host '== perl Configure ==' -ForegroundColor Cyan
    & perl Configure $Target "--prefix=$InstallPrefix" "--openssldir=$OpenSSLDir"
    if ($LASTEXITCODE -ne 0) { throw "Configure failed (exit $LASTEXITCODE)" }

    Write-Host '== nmake ==' -ForegroundColor Cyan
    & nmake
    if ($LASTEXITCODE -ne 0) { throw "nmake failed (exit $LASTEXITCODE)" }

    if (-not $SkipTests) {
        Write-Host '== nmake test ==' -ForegroundColor Cyan
        & nmake test
        if ($LASTEXITCODE -ne 0) { throw "nmake test failed (exit $LASTEXITCODE)" }
    }

    Write-Host ''
    Write-Host "Build complete. Run .\install.ps1 to install to $InstallPrefix." -ForegroundColor Green
}
finally {
    Pop-Location
}
