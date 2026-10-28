[Setup]
AppName=MaterialVless
AppVersion=1.0.1
AppPublisher=qkryt
DefaultDirName={autopf}\MaterialVless
DefaultGroupName=MaterialVless
UninstallDisplayIcon={app}\material_vless.exe
Compression=lzma2/max
SolidCompression=yes
OutputDir=..
OutputBaseFilename=MaterialVless-Windows-x86-Setup
PrivilegesRequired=admin

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\dist_x86\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MaterialVless"; Filename: "{app}\material_vless.exe"
Name: "{group}\{cm:UninstallProgram,MaterialVless}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MaterialVless"; Filename: "{app}\material_vless.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\material_vless.exe"; Description: "{cm:LaunchProgram,MaterialVless}"; Flags: nowait postinstall skipifsilent
