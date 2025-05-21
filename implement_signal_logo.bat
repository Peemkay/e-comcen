@echo off
echo Signal Logo Implementation
echo ========================
echo.

set PROJECT_DIR=C:\Users\chaki\Documents\Projects Augment\NASDS
set IMAGES_DIR=%PROJECT_DIR%\assets\images
set LOGO_PATH=%IMAGES_DIR%\nas_logo.png
set ICON_PATH=%IMAGES_DIR%\nas_icon.png

echo Creating images directory...
if not exist "%IMAGES_DIR%" mkdir "%IMAGES_DIR%"

echo.
echo Checking if logo files exist...
if exist "%LOGO_PATH%" (
    echo Logo file found at: %LOGO_PATH%
) else (
    echo Logo file not found!
    echo Please save the signal logo image to: %LOGO_PATH%
    echo You can right-click on the image in the chat and select 'Save image as...'
    pause
    exit /b 1
)

if exist "%ICON_PATH%" (
    echo Icon file found at: %ICON_PATH%
) else (
    echo Icon file not found!
    echo Copying logo to icon location...
    copy "%LOGO_PATH%" "%ICON_PATH%" /Y
    if exist "%ICON_PATH%" (
        echo Icon file created successfully.
    ) else (
        echo Failed to create icon file.
        echo Please manually save the signal logo image to: %ICON_PATH%
        pause
        exit /b 1
    )
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

