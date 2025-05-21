@echo off
echo Nigerian Army Signals Logo Implementation
echo =======================================
echo.

set PROJECT_DIR=C:\Users\chaki\Documents\Projects Augment\NASDS
set IMAGES_DIR=%PROJECT_DIR%\assets\images
set LOGO_PATH=%IMAGES_DIR%\nas_logo.png
set ICON_PATH=%IMAGES_DIR%\nas_icon.png

echo Creating images directory...
if not exist "%IMAGES_DIR%" mkdir "%IMAGES_DIR%"

echo.
echo Please save the Nigerian Army Signals logo to:
echo %LOGO_PATH%
echo.
echo You can right-click on the image in the chat and select 'Save image as...'
echo.
pause

echo.
echo Checking if logo file exists...
if exist "%LOGO_PATH%" (
    echo Logo file found!
    echo Copying logo to icon location...
    copy "%LOGO_PATH%" "%ICON_PATH%" /Y
) else (
    echo Logo file not found!
    echo Please save the logo file to %LOGO_PATH% before continuing.
    pause
    exit /b 1
)

echo.
echo Generating app icons...
cd "%PROJECT_DIR%"
call flutter pub get
call flutter pub run flutter_launcher_icons

echo.
echo Implementation complete!
echo You can now run the app to see the logo in action:
echo flutter run -d windows
echo.
pause
