# NASDS Windows Setup Guide

This guide provides instructions for running the NASDS (Electronic Communications Center) application on Windows.

## Prerequisites

Before you can run the NASDS application, you need to have the following installed:

1. **Flutter SDK** - The application is built using Flutter. Make sure Flutter is installed and in your PATH.
2. **Visual Studio** - Required for Windows development with Flutter.
3. **Git** - For version control and cloning the repository.

## Running the Application

### Option 1: Quick Run

To quickly run the application in debug mode:

1. Open a PowerShell terminal in the project directory.
2. Run the following command:

```powershell
flutter run -d windows
```

### Option 2: Build and Run

To build the application and run it:

1. Open a PowerShell terminal in the project directory.
2. Run the provided PowerShell script:

```powershell
.\run_nasds.ps1
```

This script will check if the application is already built, and if not, it will guide you on how to build it.

### Option 3: Setup with Shortcuts

To build the application and create desktop and Start Menu shortcuts:

1. Open a PowerShell terminal in the project directory.
2. Run the provided PowerShell script:

```powershell
.\setup_nasds_windows.ps1
```

This script will:
- Build the application for Windows
- Create a desktop shortcut
- Create a Start Menu shortcut
- Launch the application

## Creating an Installer

To create a Windows installer package (MSIX):

1. Open a PowerShell terminal in the project directory.
2. Run the provided PowerShell script:

```powershell
.\create_nasds_installer.ps1
```

This script will create an MSIX installer package in the `installer` directory.

## Troubleshooting

### Common Issues

1. **Flutter not found**: Make sure Flutter is installed and in your PATH.
   ```powershell
   where flutter
   ```

2. **Build errors**: If you encounter build errors, try cleaning the project:
   ```powershell
   flutter clean
   flutter pub get
   ```

3. **Plugin issues**: If you encounter issues with plugins, check the pubspec.yaml file and make sure all dependencies are compatible with Windows.

4. **Permission issues**: Run PowerShell as Administrator if you encounter permission issues.

### Getting Help

If you encounter any issues not covered in this guide, please contact the development team for assistance.

## License

This application is proprietary software developed for the Nigerian Army Signal. All rights reserved.
