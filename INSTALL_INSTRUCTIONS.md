# NASDS Installation Instructions

This document provides instructions for building and installing the NASDS (Nigerian Army Signal Dispatch System) application on Windows.

## Prerequisites

1. **Flutter SDK**: Make sure you have Flutter installed and configured properly.
2. **Visual Studio**: Install Visual Studio with the "Desktop development with C++" workload.
3. **NSIS**: Install Nullsoft Scriptable Install System (NSIS) for creating the installer.

## Building the Application

### Step 1: Build the Windows Release Version

```bash
flutter build windows --release
```

This will create the release build in the `build\windows\x64\runner\Release` directory.

### Step 2: Create Shortcuts (Optional)

If you just want to create shortcuts without creating an installer, run:

```bash
create_shortcuts.bat
```

This will create shortcuts on the desktop and in the Start Menu.

### Step 3: Create the Installer

To create a full installer, you need NSIS installed. Then run:

```bash
makensis installer.nsi
```

This will create an installer named `NASDS_Setup.exe` in the project root directory.

## Installation

### Method 1: Using the Installer

1. Run `NASDS_Setup.exe`
2. Follow the installation wizard
3. The application will be installed in the Program Files directory
4. Shortcuts will be created on the desktop and in the Start Menu

### Method 2: Manual Installation

1. Copy the contents of the `build\windows\x64\runner\Release` directory to your desired location
2. Run `create_shortcuts.bat` to create shortcuts (modify the script if needed to point to your installation location)

## Uninstallation

If you installed using the installer, you can uninstall through Windows Control Panel or by running the uninstaller directly from the installation directory.

If you installed manually, simply delete the application directory and any shortcuts you created.

## Troubleshooting

### Common Issues

1. **Application doesn't start**: Make sure all DLLs are in the same directory as the executable.
2. **Missing Visual C++ Redistributable**: Install the latest Visual C++ Redistributable package from Microsoft.
3. **Permission issues**: Try running the installer as administrator.

### Getting Help

If you encounter any issues, please contact the development team for assistance.
