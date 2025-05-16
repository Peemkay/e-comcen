# NASDS Application Launcher

This package provides scripts to run the NASDS application directly from the root directory `C:\Users\chaki\Documents\Projects Augment\NASDS`.

## Available Scripts

### 1. `run_nasds.bat`

A simple batch file that runs the main NASDS application.

**Usage:**
- Double-click the file to run
- The script will automatically navigate to the `nasds` directory and run the Flutter application

### 2. `run_nasds_complete.bat`

A more comprehensive batch file with a menu interface that allows you to:
- Run the main NASDS application
- Run the NASDS Dispatcher application
- Clean and rebuild the application
- Exit

**Usage:**
- Double-click the file to run
- Select an option from the menu by entering the corresponding number

### 3. `run_nasds.ps1`

A PowerShell script with enhanced functionality and colored output that provides the same options as `run_nasds_complete.bat`.

**Usage:**
- Right-click the file and select "Run with PowerShell"
- If you get a security warning, you may need to run the following command in PowerShell as Administrator:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
  ```
- Select an option from the menu by entering the corresponding number

### 4. `create_desktop_shortcuts.ps1`

A PowerShell script that creates desktop shortcuts for the NASDS application.

**Usage:**
- Right-click the file and select "Run with PowerShell"
- The script will create two shortcuts on your desktop:
  - "NASDS Application" - Launches the batch file menu
  - "NASDS Application (PowerShell)" - Launches the PowerShell menu

## Requirements

- Flutter SDK installed and added to your PATH
- Windows operating system
- PowerShell 5.0 or later (for PowerShell scripts)

## Troubleshooting

If you encounter any issues:

1. **Flutter not found**
   - Make sure Flutter is installed and added to your PATH
   - Try running `flutter doctor` in a command prompt to verify your Flutter installation

2. **Permission errors**
   - Try running the scripts as Administrator
   - For PowerShell scripts, you may need to adjust the execution policy

3. **Application fails to start**
   - Check the error messages in the console
   - Try running with the `--verbose` flag for more detailed output
   - Make sure all dependencies are installed by running `flutter pub get` in the `nasds` directory

## Additional Information

These scripts are designed to make it easier to run the NASDS application from the root directory. They automatically navigate to the correct directory and run the appropriate commands.

If you need to modify the scripts, you can edit them with any text editor.

For more information about the NASDS application, please refer to the documentation in the `nasds` directory.
