@echo off
echo Creating shortcuts for NASDS application...

REM Set the paths
set "APP_PATH=%~dp0build\windows\x64\runner\Release\nasds.exe"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
set "START_MENU_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
set "SHORTCUT_NAME=NASDS.lnk"

REM Check if the application exists
if not exist "%APP_PATH%" (
    echo Error: Application not found at %APP_PATH%
    echo Please build the application first with: flutter build windows --release
    exit /b 1
)

REM Create desktop shortcut
echo Creating desktop shortcut...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP_PATH%\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%APP_PATH%'; $Shortcut.WorkingDirectory = '%~dp0build\windows\x64\runner\Release'; $Shortcut.Description = 'Nigerian Army Signal Dispatch System'; $Shortcut.Save()"

REM Create Start Menu folder and shortcut
echo Creating Start Menu shortcut...
if not exist "%START_MENU_PATH%\NASDS" mkdir "%START_MENU_PATH%\NASDS"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_PATH%\NASDS\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%APP_PATH%'; $Shortcut.WorkingDirectory = '%~dp0build\windows\x64\runner\Release'; $Shortcut.Description = 'Nigerian Army Signal Dispatch System'; $Shortcut.Save()"

echo Shortcuts created successfully!
echo Desktop: %DESKTOP_PATH%\%SHORTCUT_NAME%
echo Start Menu: %START_MENU_PATH%\NASDS\%SHORTCUT_NAME%
pause
