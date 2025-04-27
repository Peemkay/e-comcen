# Updating the NASDS Windows Application Icon

This guide will help you update the Windows application icon for the NASDS (Nigerian Army Signal Dispatch Service) application.

## Files Created

1. `windows/runner/resources/nasds_icon.svg` - A new SVG icon based on the NASDS logo
2. `update_windows_icon.bat` - A batch file with instructions for updating the icon
3. `convert_icon.ps1` - A PowerShell script for converting SVG to ICO (requires ImageMagick)

## Manual Method (Recommended)

1. Use an online converter to convert the SVG to ICO:
   - [Convertio](https://convertio.co/svg-ico/)
   - [CloudConvert](https://cloudconvert.com/svg-to-ico)
   - [SVG2ICO](https://www.aconvert.com/icon/svg-to-ico/)

2. When converting, make sure to include multiple sizes in the ICO file:
   - 16x16
   - 32x32
   - 48x48
   - 64x64
   - 128x128
   - 256x256

3. Save the converted ICO file as `app_icon.ico` in the `windows/runner/resources` folder, replacing the existing file.

4. Rebuild the application:
   ```
   flutter clean
   flutter build windows
   ```

## Using ImageMagick (Advanced)

If you have ImageMagick installed, you can use the provided PowerShell script:

1. Install [ImageMagick](https://imagemagick.org/script/download.php) if you don't have it already.

2. Run the PowerShell script:
   ```
   powershell -ExecutionPolicy Bypass -File convert_icon.ps1
   ```

3. Rebuild the application:
   ```
   flutter clean
   flutter build windows
   ```

## Verifying the Icon Change

After rebuilding the application, the new icon should appear:

1. In the Windows taskbar when the app is running
2. In the application window's title bar
3. In the Windows Start menu
4. In File Explorer when viewing the executable

If the icon doesn't update immediately, you may need to clear the Windows icon cache:

1. Close all instances of File Explorer
2. Run Command Prompt as Administrator
3. Execute: `ie4uinit.exe -show`
4. Restart your computer

## Troubleshooting

- If the icon appears pixelated, ensure your ICO file contains all the recommended sizes.
- If the icon doesn't change at all, make sure you're replacing the correct file and rebuilding the application.
- For best results, use a professional icon editor like Adobe Illustrator or Inkscape to prepare the SVG before conversion.
