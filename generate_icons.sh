#!/bin/bash
# Script to generate app icons for NASDS

echo -e "\033[0;32mGenerating app icons for NASDS...\033[0m"

# Ensure we're in the right directory
CURRENT_DIR=$(pwd)
echo "Current directory: $CURRENT_DIR"

# Check if the SVG file exists
SVG_PATH="assets/images/nas_icon.svg"
if [ ! -f "$SVG_PATH" ]; then
    echo -e "\033[0;31mError: SVG icon not found at $SVG_PATH\033[0m"
    exit 1
fi

# Create a PNG version of the SVG for flutter_launcher_icons
echo "Converting SVG to PNG..."
PNG_PATH="assets/images/nas_icon.png"

# Try using Inkscape if available
if command -v inkscape &> /dev/null; then
    inkscape --export-filename="$PNG_PATH" --export-width=1024 --export-height=1024 "$SVG_PATH"
    
    if [ -f "$PNG_PATH" ]; then
        echo -e "\033[0;32mSuccessfully created PNG at $PNG_PATH\033[0m"
    else
        echo -e "\033[0;33mFailed to create PNG using Inkscape\033[0m"
        CONVERSION_FAILED=true
    fi
# Try using ImageMagick if available
elif command -v convert &> /dev/null; then
    convert -background none -size 1024x1024 "$SVG_PATH" "$PNG_PATH"
    
    if [ -f "$PNG_PATH" ]; then
        echo -e "\033[0;32mSuccessfully created PNG at $PNG_PATH\033[0m"
    else
        echo -e "\033[0;33mFailed to create PNG using ImageMagick\033[0m"
        CONVERSION_FAILED=true
    fi
else
    echo -e "\033[0;33mWarning: Could not find Inkscape or ImageMagick for SVG to PNG conversion.\033[0m"
    CONVERSION_FAILED=true
fi

if [ "$CONVERSION_FAILED" = true ]; then
    echo -e "\033[0;33mPlease manually convert the SVG to PNG and save it as 'assets/images/nas_icon.png'\033[0m"
    
    # Ask user if they want to continue
    read -p "Do you want to continue anyway? (y/n) " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

# Run flutter pub get to ensure dependencies are up to date
echo -e "\033[0;36mRunning flutter pub get...\033[0m"
flutter pub get

# Run flutter_launcher_icons
echo -e "\033[0;36mRunning flutter_launcher_icons...\033[0m"
flutter pub run flutter_launcher_icons

echo -e "\033[0;32mIcon generation complete!\033[0m"
echo "If you encounter any issues, you may need to manually convert the SVG to PNG and run the script again."
