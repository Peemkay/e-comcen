@echo off
echo Creating shortcuts for NASDS application...
echo.

REM Set the paths
set "APP_PATH=%CD%\build\windows\x64\runner\Release\nasds.exe"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
set "START_MENU_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
set "SHORTCUT_NAME=NASDS.lnk"

REM Check if the application exists
if not exist "%APP_PATH%" (
    echo Error: Application not found at %APP_PATH%
    echo.
    echo The application must be built first. You have two options:
    echo 1. Run 'flutter build windows --release' to build the application
    echo 2. Run 'build_windows_app.bat' to build the application and create shortcuts
    echo.
    goto :end
)

REM Create desktop shortcut
echo Creating desktop shortcut...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP_PATH%\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%APP_PATH%'; $Shortcut.WorkingDirectory = '%CD%\build\windows\x64\runner\Release'; $Shortcut.Description = 'Nigerian Army Signal Dispatch System'; $Shortcut.Save()"
if %ERRORLEVEL% neq 0 (
    echo Warning: Failed to create desktop shortcut
) else (
    echo Desktop shortcut created: %DESKTOP_PATH%\%SHORTCUT_NAME%
)

REM Create Start Menu folder and shortcut
echo Creating Start Menu shortcut...
if not exist "%START_MENU_PATH%\NASDS" mkdir "%START_MENU_PATH%\NASDS"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_PATH%\NASDS\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%APP_PATH%'; $Shortcut.WorkingDirectory = '%CD%\build\windows\x64\runner\Release'; $Shortcut.Description = 'Nigerian Army Signal Dispatch System'; $Shortcut.Save()"
if %ERRORLEVEL% neq 0 (
    echo Warning: Failed to create Start Menu shortcut
) else (
    echo Start Menu shortcut created: %START_MENU_PATH%\NASDS\%SHORTCUT_NAME%
)

echo.
echo Shortcuts created successfully!

:end
echo.
echo Press any key to exit...
pause > nul
