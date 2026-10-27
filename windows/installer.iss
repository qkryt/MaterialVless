[Setup]
AppName=MaterialVless
AppVersion=1.0.0
AppPublisher=MaterialVless Team
DefaultDirName={autopf}\MaterialVless
DefaultGroupName=MaterialVless
OutputDir=.
OutputBaseFilename=MaterialVless-Windows-Setup-x64
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\MaterialVless"; Filename: "{app}\material_vless.exe"
Name: "{autodesktop}\MaterialVless"; Filename: "{app}\material_vless.exe"

[Run]
Filename: "{app}\material_vless.exe"; Description: "Запустить MaterialVless"; Flags: nowait postinstall skipifsilent