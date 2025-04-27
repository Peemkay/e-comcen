@echo off
echo ===================================================
echo NASDS Windows Icon Update
echo ===================================================
echo.
echo This script will help you update the Windows application icon.
echo.
echo Steps to complete the icon update:
echo 1. The SVG icon has been created at: windows\runner\resources\nasds_icon.svg
echo 2. You need to convert this SVG to an ICO file named "app_icon.ico"
echo 3. You can use online converters like https://convertio.co/svg-ico/ or https://cloudconvert.com/svg-to-ico
echo 4. Make sure to include multiple sizes in the ICO file (16x16, 32x32, 48x48, 64x64, 128x128, 256x256)
echo 5. Save the converted ICO file as "app_icon.ico" in the windows\runner\resources folder
echo 6. Rebuild the application with: flutter build windows
echo.
echo ===================================================
echo.
pause
