# Nigerian Army Signals Logo Assets

This directory contains various formats of the Nigerian Army Signals logo for use in the NASDS application.

## Files

- `nas_logo.png` - PNG version of the Nigerian Army Signals logo
- `nas_icon.png` - PNG version of the logo for app icons

## Manual Steps Required

Please manually copy the Nigerian Army Signals logo image to:
- `nas_logo.png`

Please manually copy the Nigerian Army Signals icon image to:
- `nas_icon.png`

If you don't have a separate icon, you can use the same image for both files.

## Usage Instructions

### For Flutter App Icons

To use these assets as app icons:

1. Install the flutter_launcher_icons package:
   ```
   flutter pub add flutter_launcher_icons --dev
   ```

2. Configure the flutter_launcher_icons in pubspec.yaml:
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

3. Run the following command to generate icons:
   ```
   flutter pub run flutter_launcher_icons
   ```

### For In-App Usage

Import the assets in your Flutter code:

```dart
Image.asset('assets/images/nas_logo.png')
```

Or use the LogoUtil class:

```dart
import 'package:nasds/utils/logo_util.dart';

// Then in your widget:
LogoUtil.getLogo(width: 200, height: 200)
```

Make sure to add these assets to your pubspec.yaml:

```yaml
assets:
  - assets/images/nas_logo.png
  - assets/images/nas_icon.png
```
