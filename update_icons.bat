@echo off
echo Updating NASDS icons and logos...

set PROJECT_DIR=C:\Users\chaki\Documents\Projects Augment\NASDS
set IMAGES_DIR=%PROJECT_DIR%\assets\images
set LOGO_SOURCE=C:\Users\chaki\Downloads\nas_logo (2).png
set LOGO_DEST=%IMAGES_DIR%\nas_logo.png
set ICON_DEST=%IMAGES_DIR%\nas_icon.png

echo.
echo Checking if images directory exists...
if not exist "%IMAGES_DIR%" (
    echo Creating images directory...
    mkdir "%IMAGES_DIR%"
)

echo.
echo Copying logo file...
copy "%LOGO_SOURCE%" "%LOGO_DEST%" /Y
if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy logo file!
    exit /b 1
)

echo.
echo Copying icon file...
copy "%LOGO_SOURCE%" "%ICON_DEST%" /Y
if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy icon file!
    exit /b 1
)

echo.
echo Generating app icons...
cd "%PROJECT_DIR%"
call flutter pub run flutter_launcher_icons

echo.
echo Implementation complete!
echo You can now run the app to see the logo in action:
echo flutter run -d windows
echo.
pause
