@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo NASDS Windows Application Builder
echo ========================================================
echo.

REM Set colors for console output
set "RED=31"
set "GREEN=32"
set "YELLOW=33"
set "BLUE=34"

REM Function to print colored text
call :print_color %BLUE% "Starting build process..."
echo.

REM Check Flutter installation
call :print_color %YELLOW% "Checking Flutter installation..."
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    call :print_color %RED% "Error: Flutter not found in PATH"
    call :print_color %YELLOW% "Please make sure Flutter is installed and in your PATH"
    goto :error
)
call :print_color %GREEN% "Flutter found!"
echo.

REM Check Flutter Windows support
call :print_color %YELLOW% "Checking Flutter Windows support..."
flutter config --no-analytics
flutter doctor -v > flutter_doctor.log
type flutter_doctor.log | findstr /C:"Windows" /C:"Visual Studio" > windows_support.log
type windows_support.log
echo.
call :print_color %GREEN% "Flutter Windows check completed"
echo.

REM Build Windows application
call :print_color %YELLOW% "Building Windows application..."
echo.
echo This may take several minutes. Please be patient.
echo.

REM First try with clean
flutter clean
if %ERRORLEVEL% neq 0 (
    call :print_color %RED% "Warning: Flutter clean failed, but continuing..."
)

REM Build Windows app
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    call :print_color %RED% "Error: Failed to build Windows application"
    goto :error
)

call :print_color %GREEN% "Windows application built successfully!"
echo.

REM Check if the executable was created
if not exist "build\windows\x64\runner\Release\nasds.exe" (
    call :print_color %RED% "Error: Build completed but executable not found"
    goto :error
)

REM Create shortcuts
call :print_color %YELLOW% "Creating shortcuts..."
echo.

REM Create desktop shortcut
call :print_color %BLUE% "Creating desktop shortcut..."
set "APP_PATH=%CD%\build\windows\x64\runner\Release\nasds.exe"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
set "SHORTCUT_NAME=NASDS.lnk"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP_PATH%\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%APP_PATH%'; $Shortcut.WorkingDirectory = '%CD%\build\windows\x64\runner\Release'; $Shortcut.Description = 'Nigerian Army Signal Dispatch System'; $Shortcut.Save()"
if %ERRORLEVEL% neq 0 (
    call :print_color %RED% "Warning: Failed to create desktop shortcut"
) else (
    call :print_color %GREEN% "Desktop shortcut created: %DESKTOP_PATH%\%SHORTCUT_NAME%"
)

REM Create Start Menu shortcut
call :print_color %BLUE% "Creating Start Menu shortcut..."
set "START_MENU_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
if not exist "%START_MENU_PATH%\NASDS" mkdir "%START_MENU_PATH%\NASDS"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_PATH%\NASDS\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%APP_PATH%'; $Shortcut.WorkingDirectory = '%CD%\build\windows\x64\runner\Release'; $Shortcut.Description = 'Nigerian Army Signal Dispatch System'; $Shortcut.Save()"
if %ERRORLEVEL% neq 0 (
    call :print_color %RED% "Warning: Failed to create Start Menu shortcut"
) else (
    call :print_color %GREEN% "Start Menu shortcut created: %START_MENU_PATH%\NASDS\%SHORTCUT_NAME%"
)

echo.
call :print_color %GREEN% "Build process completed successfully!"
echo.
call :print_color %BLUE% "Application location: %CD%\build\windows\x64\runner\Release\nasds.exe"
echo.
echo You can now distribute the application by:
echo 1. Copying the entire Release folder to another computer
echo 2. Running the application by double-clicking nasds.exe
echo.
goto :end

:error
call :print_color %RED% "Build process failed!"
exit /b 1

:end
echo Press any key to exit...
pause > nul
exit /b 0

:print_color
echo [%~1m%~2[0m
exit /b 0
