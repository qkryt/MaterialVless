[Setup]
AppName=MaterialVless
AppVersion=2.15.1
AppPublisher=qkryt
DefaultDirName={autopf}\MaterialVless
DefaultGroupName=MaterialVless
UninstallDisplayIcon={app}\app_icon.ico
SetupIconFile=..\assets\icons\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
OutputDir=..
OutputBaseFilename=MaterialVless-Windows-x86-Setup
ArchitecturesInstallIn64BitMode=
PrivilegesRequired=admin

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\dist_x86\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\assets\rules\*"; DestDir: "{app}\rules"; Flags: ignoreversion

[Icons]
Name: "{group}\MaterialVless"; Filename: "{app}\material_vless.exe"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\{cm:UninstallProgram,MaterialVless}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MaterialVless"; Filename: "{app}\material_vless.exe"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Registry]
Root: HKCR; Subkey: "material"; ValueType: string; ValueName: ""; ValueData: "URL:MaterialVless Protocol"; Flags: uninsdeletekey
Root: HKCR; Subkey: "material"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Flags: uninsdeletekey
Root: HKCR; Subkey: "material\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\material_vless.exe,0"
Root: HKCR; Subkey: "material\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\material_vless.exe"" ""%1"""

Root: HKCR; Subkey: "happ"; ValueType: string; ValueName: ""; ValueData: "URL:Happ Protocol"; Flags: uninsdeletekey
Root: HKCR; Subkey: "happ"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Flags: uninsdeletekey
Root: HKCR; Subkey: "happ\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\material_vless.exe,0"
Root: HKCR; Subkey: "happ\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\material_vless.exe"" ""%1"""

[Run]
Filename: "{app}\material_vless.exe"; Description: "{cm:LaunchProgram,MaterialVless}"; Flags: nowait postinstall skipifsilent

[Dirs]
Name: "{app}"; Permissions: users-modify
Name: "{app}\customfonts"; Permissions: users-modify
Name: "{app}\rules"; Permissions: users-modify
Name: "{app}\backgrounds"; Permissions: users-modify
