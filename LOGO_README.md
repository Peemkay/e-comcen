# Nigerian Army Signals Logo Integration

This document provides instructions for using the Nigerian Army Signals logo in the NASDS application.

## Logo Files

The following logo files should be placed in the assets/images directory:

- `assets/images/nas_logo.png` - PNG version of the Nigerian Army Signals logo
- `assets/images/nas_icon.png` - PNG version of the logo for app icons (can be the same as nas_logo.png)

## Manual Steps Required

1. Save the Nigerian Army Signals logo image to:
   - `assets/images/nas_logo.png`

2. Save the Nigerian Army Signals icon image to:
   - `assets/images/nas_icon.png`
   - (If you don't have a separate icon, the script will copy the logo file to use as the icon)

## Using the Logo in the App

The logo has been integrated into the app through the `LogoUtil` class located at `lib/utils/logo_util.dart`. This class provides methods for displaying the logo in various formats:

```dart
// Display the full logo
LogoUtil.getLogo(width: 200, height: 200)

// Display the icon
LogoUtil.getIcon(width: 100, height: 100)

// Display the logo as a square with equal width and height
LogoUtil.getSquareLogo(150)

// Display the logo as a circular avatar
LogoUtil.getCircularLogo(75)
```

The `PlaceholderLogo` widget has been updated to use the new logo, so any existing code that uses this widget will automatically display the new logo.

## Generating App Icons

To generate app icons for all platforms (Android, iOS, Windows, Web), run the provided script:

### On Windows:

```powershell
.\generate_icons.ps1
```

This will:
1. Check if the logo and icon files exist
2. Copy the logo to the icon location if needed
3. Run the flutter_launcher_icons package to generate icons for all platforms

## Manual Icon Generation

If you need to manually generate the icons, run:

```bash
flutter pub run flutter_launcher_icons
```

## Configuration

The flutter_launcher_icons configuration is in the `pubspec.yaml` file:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/nas_logo.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/images/nas_logo.png"
    background_color: "#000066"
    theme_color: "#FFFF00"
  windows:
    generate: true
    image_path: "assets/images/nas_logo.png"
    icon_size: 48
```

## MSIX Configuration

The MSIX configuration for Windows has been updated to use the new logo:

```yaml
msix_config:
  logo_path: assets/images/nas_icon.png
  start_menu_icon_path: assets/images/nas_icon.png
  tile_icon_path: assets/images/nas_icon.png
```
