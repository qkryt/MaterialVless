[Setup]
AppName=MaterialVless
AppVersion=2.0.0
AppPublisher=qkryt
DefaultDirName={autopf}\MaterialVless
DefaultGroupName=MaterialVless
UninstallDisplayIcon={app}\material_vless.exe
SetupIconFile=..\assets\icons\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
OutputDir=..
OutputBaseFilename=MaterialVless-Windows-x64-Setup
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MaterialVless"; Filename: "{app}\material_vless.exe"
Name: "{group}\{cm:UninstallProgram,MaterialVless}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MaterialVless"; Filename: "{app}\material_vless.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\material_vless.exe"; Description: "{cm:LaunchProgram,MaterialVless}"; Flags: nowait postinstall skipifsilent
