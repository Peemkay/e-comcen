# How to Run NASDS Applications

This document provides simple instructions for running the NASDS applications directly from the command line.

## Prerequisites

- Flutter SDK installed and in your PATH
- Windows operating system

## Running the Applications

### Option 1: Using the Helper Scripts

The simplest way to run the applications is to use the provided helper scripts:

- **Command Prompt**: Double-click `run_app.bat` or run it from Command Prompt
- **PowerShell**: Right-click `run_app.ps1` and select "Run with PowerShell"

These scripts will:
1. Check if the app is already running
2. Ask if you want to close the running instance
3. Let you choose which application to run (Main or Dispatcher)

### Option 2: Direct Commands

#### Main NASDS Application

To run the main NASDS application, open Command Prompt or PowerShell and execute:

```
cd nasds
flutter run -d windows
```

#### NASDS Dispatch Application

To run the NASDS Dispatcher application, open Command Prompt or PowerShell and execute:

```
cd nasds
flutter run -d windows --dart-define=APP_MODE=dispatcher
```

### Checking for Running Instances

Before starting the application, you may want to check if it's already running:

```
tasklist /fi "imagename eq nasds.exe"
```

To kill any running instances:

```
taskkill /f /im nasds.exe
```

## Troubleshooting

If you encounter any issues:

1. **Flutter not found in PATH**:
   - Add Flutter to your PATH environment variable:
   ```
   set PATH=C:\path\to\flutter\bin;%PATH%
   ```
   - Or in PowerShell:
   ```
   $env:Path = "C:\path\to\flutter\bin;$env:Path"
   ```

2. **Clean the project if needed**:
   ```
   cd nasds
   flutter clean
   flutter pub get
   ```

3. **Check available devices**:
   ```
   flutter devices
   ```
   Make sure Windows is listed as an available device.

4. **Run with verbose output for debugging**:
   ```
   flutter run -d windows --verbose
   ```
   or
   ```
   flutter run -d windows --target lib/main_dispatch.dart --verbose
   ```
