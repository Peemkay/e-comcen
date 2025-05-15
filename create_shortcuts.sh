#!/bin/bash
echo "Creating shortcuts for NASDS application..."

# Set the paths (convert Windows paths to Git Bash paths)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$SCRIPT_DIR/build/windows/x64/runner/Release/nasds.exe"
DESKTOP_PATH="$HOME/Desktop"
START_MENU_PATH="$APPDATA/Microsoft/Windows/Start Menu/Programs"
SHORTCUT_NAME="NASDS.lnk"

# Check if the application exists
if [ ! -f "$APP_PATH" ]; then
    echo "Error: Application not found at $APP_PATH"
    echo "Please build the application first with: flutter build windows --release"
    exit 1
fi

# Create desktop shortcut using PowerShell
echo "Creating desktop shortcut..."
powershell.exe -Command "\$WshShell = New-Object -ComObject WScript.Shell; \$Shortcut = \$WshShell.CreateShortcut('$DESKTOP_PATH\\$SHORTCUT_NAME'); \$Shortcut.TargetPath = '$APP_PATH'; \$Shortcut.WorkingDirectory = '$(dirname "$APP_PATH")'; \$Shortcut.Description = 'Nigerian Army Signal Dispatch System'; \$Shortcut.Save()"

# Create Start Menu folder and shortcut
echo "Creating Start Menu shortcut..."
mkdir -p "$START_MENU_PATH/NASDS"
powershell.exe -Command "\$WshShell = New-Object -ComObject WScript.Shell; \$Shortcut = \$WshShell.CreateShortcut('$START_MENU_PATH\\NASDS\\$SHORTCUT_NAME'); \$Shortcut.TargetPath = '$APP_PATH'; \$Shortcut.WorkingDirectory = '$(dirname "$APP_PATH")'; \$Shortcut.Description = 'Nigerian Army Signal Dispatch System'; \$Shortcut.Save()"

echo "Shortcuts created successfully!"
echo "Desktop: $DESKTOP_PATH/$SHORTCUT_NAME"
echo "Start Menu: $START_MENU_PATH/NASDS/$SHORTCUT_NAME"
read -p "Press Enter to continue..."
