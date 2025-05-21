@echo off
echo E-COMCEN Logo Implementation
echo ============================
echo.

set PROJECT_DIR=C:\Users\chaki\Documents\Projects Augment\NASDS
set IMAGES_DIR=%PROJECT_DIR%\assets\images
set LOGO_PATH=%IMAGES_DIR%\nas_logo.png
set ICON_PATH=%IMAGES_DIR%\nas_icon.png

echo Creating images directory...
if not exist "%IMAGES_DIR%" mkdir "%IMAGES_DIR%"

echo.
echo Please make sure you have downloaded the E-COMCEN logo files:
echo 1. nas_logo.png
echo 2. nas_icon.png
echo.
echo These files should be in your Downloads folder or where your browser saves downloads.
echo.
pause

echo.
echo Checking if logo files exist in Downloads folder...
if exist "%USERPROFILE%\Downloads\nas_logo.png" (
    echo Found nas_logo.png in Downloads folder!
    echo Copying to project...
    copy "%USERPROFILE%\Downloads\nas_logo.png" "%LOGO_PATH%" /Y
    echo Logo copied successfully!
) else (
    echo Logo file not found in Downloads folder.
    echo Please manually copy nas_logo.png to: %LOGO_PATH%
)

if exist "%USERPROFILE%\Downloads\nas_icon.png" (
    echo Found nas_icon.png in Downloads folder!
    echo Copying to project...
    copy "%USERPROFILE%\Downloads\nas_icon.png" "%ICON_PATH%" /Y
    echo Icon copied successfully!
) else (
    echo Icon file not found in Downloads folder.
    echo Please manually copy nas_icon.png to: %ICON_PATH%
)

echo.
echo Checking if logo files exist in project...
if exist "%LOGO_PATH%" (
    echo Logo file found in project!
) else (
    echo Logo file not found in project!
    echo Please manually copy nas_logo.png to: %LOGO_PATH%
    echo before continuing.
    pause
)

if exist "%ICON_PATH%" (
    echo Icon file found in project!
) else (
    echo Icon file not found in project!
    echo Please manually copy nas_icon.png to: %ICON_PATH%
    echo before continuing.
    pause
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
