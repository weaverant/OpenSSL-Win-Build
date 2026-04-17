[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcDir    = Join-Path $ScriptDir 'openssl'

if (-not (Test-Path (Join-Path $SrcDir 'makefile'))) {
    throw "No makefile at $SrcDir. Run .\build.ps1 first."
}

if (-not (Get-Command nmake.exe -ErrorAction SilentlyContinue)) {
    throw "nmake.exe not on PATH. Launch from 'x64 Native Tools Command Prompt for VS 2022'."
}

$prefix = $null
$cfg = Join-Path $SrcDir 'configdata.pm'
if (Test-Path $cfg) {
    $m = Select-String -Path $cfg -Pattern '"prefix"\s*=>\s*"([^"]+)"' | Select-Object -First 1
    if ($m) { $prefix = $m.Matches[0].Groups[1].Value -replace '\\\\', '\' }
}

if ($prefix) {
    Write-Host "Installing to: $prefix"
    if ($prefix -like 'C:\Program Files\*' -or $prefix -like 'C:\Program Files (x86)\*') {
        $isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Warning 'Target is under Program Files; install will fail without admin rights. Re-launch this shell as Administrator.'
        }
    }
}

Push-Location $SrcDir
try {
    Write-Host '== nmake install ==' -ForegroundColor Cyan
    & nmake install
    if ($LASTEXITCODE -ne 0) { throw "nmake install failed (exit $LASTEXITCODE)" }
    Write-Host 'Install complete.' -ForegroundColor Green
}
finally {
    Pop-Location
}
