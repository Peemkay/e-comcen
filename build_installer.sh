#!/bin/bash
echo "Building NASDS Windows Application and Installer"
echo "==============================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found in PATH"
    echo "Please install Flutter and add it to your PATH"
    exit 1
fi

# Check if NSIS is installed
if ! command -v makensis &> /dev/null; then
    echo "Warning: NSIS not found in PATH"
    echo "You can still build the application, but the installer won't be created"
    NSIS_FOUND=0
else
    NSIS_FOUND=1
fi

# Build the Windows application
echo "Building Windows application..."
flutter clean
flutter build windows --release

if [ $? -ne 0 ]; then
    echo "Error: Failed to build Windows application"
    exit 1
fi

echo "Windows application built successfully!"

# Create shortcuts using the batch file via cmd
echo "Creating shortcuts..."
cmd.exe /c create_shortcuts.bat

# Create installer if NSIS is available
if [ $NSIS_FOUND -eq 1 ]; then
    echo "Creating installer..."
    makensis installer.nsi
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create installer"
        exit 1
    fi
    
    echo "Installer created successfully: NASDS_Setup.exe"
else
    echo "Skipping installer creation (NSIS not found)"
fi

echo "Build process completed successfully!"
echo "You can find the application in: build/windows/x64/runner/Release"
if [ $NSIS_FOUND -eq 1 ]; then
    echo "You can find the installer in: NASDS_Setup.exe"
fi

read -p "Press Enter to continue..."
