@echo off
echo Building NASDS Windows Application and Installer
echo ===============================================

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Flutter not found in PATH
    echo Please install Flutter and add it to your PATH
    exit /b 1
)

REM Check if NSIS is installed
where makensis >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Warning: NSIS not found in PATH
    echo You can still build the application, but the installer won't be created
    set NSIS_FOUND=0
) else (
    set NSIS_FOUND=1
)

REM Build the Windows application
echo Building Windows application...
flutter clean
flutter build windows --release

if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build Windows application
    exit /b 1
)

echo Windows application built successfully!

REM Create shortcuts
echo Creating shortcuts...
call create_shortcuts.bat

REM Create installer if NSIS is available
if %NSIS_FOUND% equ 1 (
    echo Creating installer...
    makensis installer.nsi
    
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to create installer
        exit /b 1
    )
    
    echo Installer created successfully: NASDS_Setup.exe
) else (
    echo Skipping installer creation (NSIS not found)
)

echo Build process completed successfully!
echo You can find the application in: build\windows\x64\runner\Release
if %NSIS_FOUND% equ 1 (
    echo You can find the installer in: NASDS_Setup.exe
)
pause
