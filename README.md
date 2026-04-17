# OpenSSL-Win-Build

Windows build recipe for OpenSSL from source.

Tracks upstream [openssl/openssl](https://github.com/openssl/openssl) as a git
submodule pinned to a release tag. Scripts default to the conventional
Windows install layout (`C:\Program Files\OpenSSL-Win64` +
`C:\Program Files\Common Files\SSL`).

## Prerequisites

- **Visual Studio 2022** (Community or Build Tools) with the "Desktop development
  with C++" workload — provides `cl`, `nmake`, `link`.
- **[Strawberry Perl](https://strawberryperl.com/)** — add its `perl\bin`
  subdirectory to `PATH`.
- **[NASM](https://www.nasm.us/)** — add the folder containing `nasm.exe` to `PATH`.
- **Git**.

All scripts must be run from a shell that has the MSVC toolchain active.
Easiest: launch **"x64 Native Tools Command Prompt for VS 2022"** from the
Start menu, then start PowerShell in it:

    pwsh

## Clone

    git clone --recurse-submodules https://github.com/weaverant/OpenSSL-Win-Build.git
    cd OpenSSL-Win-Build

If you forgot `--recurse-submodules`:

    git submodule update --init

## Build

Default layout:

    .\build.ps1

Custom install location, single self-contained tree:

    .\build.ps1 -InstallPrefix C:\OpenSSL-Local -OpenSSLDir C:\OpenSSL-Local\ssl

Skip the test suite (roughly 10 minutes on a modern box):

    .\build.ps1 -SkipTests

Options:

| Switch / Param | Default | Notes |
|----------------|---------|-------|
| `-Target`        | `VC-WIN64A` | also `VC-WIN32`, `VC-WIN64-ARM`, ... (see `NOTES-WINDOWS.md` in the submodule) |
| `-InstallPrefix` | `C:\Program Files\OpenSSL-Win64` | baked into the binaries at Configure time |
| `-OpenSSLDir`    | `C:\Program Files\Common Files\SSL` | baked into the binaries at Configure time |
| `-SkipTests`     | off | |
| `-Clean`         | off | run `nmake clean` first |

## Install

    .\install.ps1

Installs to whichever prefix the last `build.ps1` used. When the target is
under `C:\Program Files\`, run from an **elevated** shell — the script warns if
it detects a non-admin session targeting a protected path.

To change the install location, re-run `build.ps1` with a new `-InstallPrefix` —
the prefix is baked in at Configure time, so a simple reinstall to a different
location is not possible.

## Updating to a newer OpenSSL release

    cd openssl
    git fetch --tags
    git checkout openssl-X.Y.Z
    cd ..
    git add openssl
    git commit -m "Bump openssl to X.Y.Z"

Then rebuild with `.\build.ps1`.
