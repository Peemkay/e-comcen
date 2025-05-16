# E-COMCEN Project

E-COMCEN (Electronic Communications Center) is a comprehensive communications and dispatch management system for Nigerian Army Signal units. This project consists of two applications:

1. **E-COMCEN (Main Application)** - Used by admin users to manage all aspects of the dispatch system
2. **E-COMCEN-DSM (Dispatch Service Manager)** - Used by dispatchers to update dispatch status and synchronize with the main application

## Features

### E-COMCEN (Main Application)
- Admin user authentication and registration
- Comprehensive dispatch management (Incoming, Outgoing, Local, External)
- COMCEN log management
- User management
- Security features (biometric authentication, session management, etc.)
- Multi-language support with offline functionality

### E-COMCEN-DSM (Dispatch Service Manager)
- Dispatcher authentication
- View assigned dispatches
- Update dispatch status
- Track dispatch progress
- Synchronize with main E-COMCEN application

## Running the Applications

### Prerequisites
- Flutter SDK installed and in your PATH
- Windows operating system

### Running the Unified Application

The NASDS application now includes both the main and dispatcher functionality in a single application. You can run either mode using the following commands:

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

#### Using the Helper Script

Alternatively, you can use the provided helper script which will prompt you to choose which mode to run:

```
.\run_app.bat    # For Command Prompt
.\run_app.ps1    # For PowerShell
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

### Cleaning the Project

If you encounter any issues, try cleaning the project:

```
cd nasds
flutter clean
flutter pub get
flutter run -d windows
```

## Project Structure

- `nasds/` - Contains the main E-COMCEN application
- `ecomcen_dsm/` - Contains the E-COMCEN-DSM application for dispatchers

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

2. **Check available devices**:
   ```
   flutter devices
   ```
   Make sure Windows is listed as an available device.

3. **Run with verbose output for debugging**:
   ```
   flutter run -d windows --verbose
   ```
   or
   ```
   flutter run -d windows --target lib/main_dispatch.dart --verbose
   ```
