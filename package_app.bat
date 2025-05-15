@echo off
echo Packaging NASDS application for distribution...
echo.

REM Set the paths
set "APP_PATH=%CD%\build\windows\x64\runner\Release"
set "PACKAGE_NAME=NASDS_Windows"
set "PACKAGE_PATH=%CD%\%PACKAGE_NAME%"

REM Check if the application exists
if not exist "%APP_PATH%\nasds.exe" (
    echo Error: Application not found at %APP_PATH%\nasds.exe
    echo.
    echo The application must be built first. You have two options:
    echo 1. Run 'flutter build windows --release' to build the application
    echo 2. Run 'build_windows_app.bat' to build the application
    echo.
    goto :end
)

REM Create package directory
echo Creating package directory...
if exist "%PACKAGE_PATH%" rmdir /S /Q "%PACKAGE_PATH%"
mkdir "%PACKAGE_PATH%"

REM Copy application files
echo Copying application files...
xcopy "%APP_PATH%\*" "%PACKAGE_PATH%\" /E /I /H /Y

REM Copy installation scripts
echo Copying installation scripts...
copy "create_shortcuts_only.bat" "%PACKAGE_PATH%\install.bat" /Y

REM Create README file
echo Creating README file...
echo NASDS - Nigerian Army Signal Dispatch System > "%PACKAGE_PATH%\README.txt"
echo. >> "%PACKAGE_PATH%\README.txt"
echo Installation Instructions: >> "%PACKAGE_PATH%\README.txt"
echo 1. Run install.bat to create shortcuts on the desktop and in the Start Menu >> "%PACKAGE_PATH%\README.txt"
echo 2. Alternatively, you can run nasds.exe directly from this folder >> "%PACKAGE_PATH%\README.txt"
echo. >> "%PACKAGE_PATH%\README.txt"
echo Note: All files in this folder are required for the application to run properly. >> "%PACKAGE_PATH%\README.txt"
echo Do not delete or move any files unless you know what you are doing. >> "%PACKAGE_PATH%\README.txt"

REM Create ZIP file
echo Creating ZIP file...
powershell -Command "Compress-Archive -Path '%PACKAGE_PATH%\*' -DestinationPath '%CD%\%PACKAGE_NAME%.zip' -Force"
if %ERRORLEVEL% neq 0 (
    echo Warning: Failed to create ZIP file
) else (
    echo ZIP file created: %CD%\%PACKAGE_NAME%.zip
)

echo.
echo Packaging completed successfully!
echo.
echo You can distribute the application by:
echo 1. Sharing the %PACKAGE_NAME% folder
echo 2. Sharing the %PACKAGE_NAME%.zip file
echo.

:end
echo Press any key to exit...
pause > nul
