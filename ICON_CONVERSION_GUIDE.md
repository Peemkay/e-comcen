# NASDS Windows Icon Conversion Guide

This guide will help you convert the SVG icon to an ICO file for your Windows application.

## Step 1: Locate the SVG File

The SVG file is located at:
```
windows\runner\resources\nasds_icon_simple.svg
```

## Step 2: Convert SVG to ICO

You can use one of these online converter websites:

1. **Convertio**: https://convertio.co/svg-ico/
2. **CloudConvert**: https://cloudconvert.com/svg-to-ico

### Conversion Settings

When converting, make sure to include these sizes in your ICO file:
- 16x16
- 32x32
- 48x48
- 64x64
- 128x128
- 256x256

These sizes are standard for Windows applications and will ensure your icon looks good at all display sizes.

## Step 3: Save the ICO File

Save the downloaded ICO file as:
```
windows\runner\resources\app_icon.ico
```

If this file already exists, replace it with your new file.

## Step 4: Rebuild Your Application

After replacing the icon file, rebuild your Flutter application to apply the changes:

```
flutter clean
flutter build windows
```

## Troubleshooting

If the icon doesn't appear to change:
1. Make sure you've saved the ICO file with the correct name and in the correct location
2. Try clearing your Flutter build cache with `flutter clean` before rebuilding
3. Check that your ICO file includes all the required sizes
4. Restart your development environment

## Alternative Method (Using ImageMagick)

If you have ImageMagick installed, you can use the PowerShell script `convert_icon.ps1` in the project root to convert the SVG to ICO automatically.
