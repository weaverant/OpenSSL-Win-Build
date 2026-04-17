; Inno Setup 6 script for OpenSSL-Win-Build.
;
; Invoke via pack.ps1 (passes /DVersion=, /DStageRoot=, /DOutputDir=,
; /DSourceRoot= on the iscc command line).

#ifndef Version
  #error Version is required (pass via /DVersion=X.Y.Z)
#endif
#ifndef StageRoot
  #error StageRoot is required (pass via /DStageRoot=<path>)
#endif
#ifndef OutputDir
  #define OutputDir "dist"
#endif
#ifndef SourceRoot
  #define SourceRoot "."
#endif

[Setup]
AppId={{F8D5E4A3-9C6B-4F2D-8E1A-3B7C9D5F4E2A}}
AppName=OpenSSL
AppVersion={#Version}
AppVerName=OpenSSL {#Version} (64-bit)
AppPublisher=weaverant
AppPublisherURL=https://github.com/weaverant/OpenSSL-Win-Build
AppSupportURL=https://github.com/weaverant/OpenSSL-Win-Build/issues
AppUpdatesURL=https://github.com/weaverant/OpenSSL-Win-Build/releases

DefaultDirName={autopf}\OpenSSL-Win64
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=no
UsePreviousAppDir=yes

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

Compression=lzma2
SolidCompression=yes
LZMAUseSeparateProcess=yes

LicenseFile={#SourceRoot}\openssl\LICENSE.txt

OutputBaseFilename=OpenSSL-Win64-{#Version}-setup
OutputDir={#OutputDir}

UninstallDisplayIcon={app}\bin\openssl.exe
UninstallDisplayName=OpenSSL {#Version} (64-bit)

WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "addtopath"; Description: "Add the OpenSSL bin directory to the system PATH"; \
  GroupDescription: "Additional tasks:"; Flags: unchecked

[Files]
; Prefix tree: C:\Program Files\OpenSSL-Win64\*
Source: "{#StageRoot}\Program Files\OpenSSL-Win64\*"; \
  DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; OPENSSLDIR tree: C:\Program Files\Common Files\SSL\*
Source: "{#StageRoot}\Program Files\Common Files\SSL\*"; \
  DestDir: "{commonpf}\Common Files\SSL"; Flags: ignoreversion recursesubdirs createallsubdirs

[Code]
const
  EnvKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';

var
  PathInfoPage: TOutputMsgWizardPage;

procedure InitializeWizard;
var
  Msg: string;
begin
  Msg :=
    'OpenSSL {#Version} (64-bit) will be installed to:' + #13#10 + #13#10 +
    '    ' + ExpandConstant('{autopf}\OpenSSL-Win64') + #13#10 + #13#10 +
    'Shared configuration and certificates go to:' + #13#10 + #13#10 +
    '    ' + ExpandConstant('{commonpf}\Common Files\SSL') + #13#10 + #13#10 +
    'These paths are compiled into the OpenSSL binaries at build time and ' +
    'cannot be changed without rebuilding OpenSSL from source. Choosing a ' +
    'different install location would prevent the binaries from finding ' +
    'openssl.cnf, the CA bundle, and provider modules at runtime.';
  PathInfoPage := CreateOutputMsgPage(wpWelcome,
    'Installation location',
    'Where OpenSSL will be installed',
    Msg);
end;

function PathContains(const Path, Needle: string): Boolean;
begin
  Result := Pos(';' + LowerCase(Needle) + ';', ';' + LowerCase(Path) + ';') > 0;
end;

procedure AddToPath(const Dir: string);
var
  Existing: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, EnvKey, 'Path', Existing) then
    Existing := '';
  if PathContains(Existing, Dir) then
    exit;
  if (Existing <> '') and (Existing[Length(Existing)] <> ';') then
    Existing := Existing + ';';
  Existing := Existing + Dir;
  RegWriteExpandStringValue(HKEY_LOCAL_MACHINE, EnvKey, 'Path', Existing);
end;

procedure RemoveFromPath(const Dir: string);
var
  Existing, LowerExisting, LowerDir: string;
  P: Integer;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, EnvKey, 'Path', Existing) then
    exit;
  LowerExisting := ';' + LowerCase(Existing) + ';';
  LowerDir := ';' + LowerCase(Dir) + ';';
  P := Pos(LowerDir, LowerExisting);
  if P = 0 then
    exit;
  Delete(Existing, P, Length(Dir) + 1);
  if (Existing <> '') and (Existing[1] = ';') then
    Delete(Existing, 1, 1);
  if (Existing <> '') and (Existing[Length(Existing)] = ';') then
    Delete(Existing, Length(Existing), 1);
  RegWriteExpandStringValue(HKEY_LOCAL_MACHINE, EnvKey, 'Path', Existing);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and IsTaskSelected('addtopath') then
    AddToPath(ExpandConstant('{app}\bin'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemoveFromPath(ExpandConstant('{app}\bin'));
end;
