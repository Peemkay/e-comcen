# PowerShell script to save the Nigerian Army Signals logo

# Define paths
$projectDir = "C:\Users\chaki\Documents\Projects Augment\NASDS"
$imagesDir = "$projectDir\assets\images"
$logoPath = "$imagesDir\nas_logo.png"
$iconPath = "$imagesDir\nas_icon.png"

# Create the images directory if it doesn't exist
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force
    Write-Host "Created directory: $imagesDir"
}

# Check if the logo file already exists
if (Test-Path $logoPath) {
    Write-Host "Logo file already exists at: $logoPath"
    Write-Host "Renaming existing file to nas_logo_old.png"
    Rename-Item -Path $logoPath -NewName "nas_logo_old.png" -Force
}

# Check if the icon file already exists
if (Test-Path $iconPath) {
    Write-Host "Icon file already exists at: $iconPath"
    Write-Host "Renaming existing file to nas_icon_old.png"
    Rename-Item -Path $iconPath -NewName "nas_icon_old.png" -Force
}

# Note: Since we can't directly save binary data through this interface,
# we'll need to instruct the user to manually copy the logo file to the assets/images directory.
Write-Host "Please manually copy the Nigerian Army Signals logo to: $logoPath"
Write-Host "Please manually copy the Nigerian Army Signals icon to: $iconPath"

# Create a placeholder README file with instructions
$readmePath = "$imagesDir\README.md"
$readmeContent = @"
# Nigerian Army Signals Logo Assets

This directory contains various formats of the Nigerian Army Signals logo for use in the NASDS application.

## Files

- `nas_logo.png` - PNG version of the Nigerian Army Signals logo
- `nas_icon.png` - PNG version of the Nigerian Army Signals icon for app icons

## Manual Steps Required

Please manually copy the Nigerian Army Signals logo image to:
- `$logoPath`

Please manually copy the Nigerian Army Signals icon image to:
- `$iconPath`

## Usage Instructions

After copying the logo files, run the following command to generate app icons:

```
flutter pub run flutter_launcher_icons
```

This will generate app icons for all platforms based on the configuration in pubspec.yaml.
"@

Set-Content -Path $readmePath -Value $readmeContent
Write-Host "Created README file with instructions at: $readmePath"

# Update the app_constants.dart file to use the new logo
$constantsPath = "$projectDir\lib\constants\app_constants.dart"
if (Test-Path $constantsPath) {
    Write-Host "Updating app_constants.dart to use the new logo..."
    $constants = Get-Content -Path $constantsPath -Raw
    $constants = $constants -replace "static const String logoPath =\s*'[^']*';", "static const String logoPath = 'assets/images/nas_logo.png'; // Nigerian Army Signals logo"
    $constants = $constants -replace "static const String iconPath =\s*'[^']*';", "static const String iconPath = 'assets/images/nas_icon.png'; // Nigerian Army Signals icon"
    Set-Content -Path $constantsPath -Value $constants
    Write-Host "Updated app_constants.dart successfully."
}

Write-Host "Script completed. Please follow the instructions in the README file."
