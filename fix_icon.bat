@echo off
echo Creating directories...
mkdir -p windows\runner\resources

echo Checking for SVG file...
if exist windows\runner\resources\nasds_icon_simple.svg (
    echo SVG file exists!
) else (
    echo SVG file not found, creating it...
    copy ..\windows\runner\resources\nasds_icon_simple.svg windows\runner\resources\
)

echo.
echo Please follow these steps:
echo 1. Go to https://convertio.co/svg-ico/
echo 2. Upload the SVG file from windows\runner\resources\nasds_icon_simple.svg
echo 3. Configure the conversion to include these sizes: 16x16, 32x32, 48x48, 64x64, 128x128, 256x256
echo 4. Download the resulting ICO file
echo 5. Save it as app_icon.ico in the windows\runner\resources directory
echo.
echo After completing these steps, run:
echo flutter clean
echo flutter build windows
echo.
pause
