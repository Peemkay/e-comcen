# E-COMCEN Installation Guide

This guide provides instructions for installing and running both the E-COMCEN main application and the E-COMCEN-DSM dispatcher application on Windows.

## Prerequisites

Before installing the applications, ensure you have the following:

1. **Flutter SDK** (version 3.0.0 or higher)
2. **Windows 10** or later
3. **Visual Studio 2019** or later with the "Desktop development with C++" workload
4. **Git** for version control

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-repository/e-comcen.git
cd e-comcen
```

### Step 2: Install Dependencies

Install dependencies for both applications:

```bash
# Install dependencies for the main application
cd nasds
flutter pub get

# Install dependencies for the dispatcher application
cd ../ecomcen_dsm
flutter pub get
cd ..
```

### Step 3: Build the Applications

#### Build the Main Application (E-COMCEN)

```bash
cd nasds
flutter build windows --release
```

The built application will be available at `nasds\build\windows\runner\Release\`.

#### Build the Dispatcher Application (E-COMCEN-DSM)

```bash
cd ecomcen_dsm
flutter build windows --release
```

The built application will be available at `ecomcen_dsm\build\windows\runner\Release\`.

### Step 4: Create Installation Packages

#### Option 1: Manual Installation

1. Copy the contents of the Release folders to your desired installation locations.
2. Create shortcuts on the desktop for easy access.

#### Option 2: Create Installer (Recommended)

You can use tools like Inno Setup to create installation packages:

1. Download and install [Inno Setup](https://jrsoftware.org/isdl.php)
2. Use the provided script files in the `installer` directory to create installers for both applications.

```bash
# Run Inno Setup Compiler with the script files
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\ecomcen_setup.iss
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\ecomcen_dsm_setup.iss
```

The installers will be created in the `installer\Output` directory.

## Running the Applications

### Running E-COMCEN (Main Application)

1. Double-click the `ecomcen.exe` file in the installation directory or use the desktop shortcut.
2. On first run, you'll need to create an administrator account.
3. Follow the on-screen instructions to set up your credentials.

### Running E-COMCEN-DSM (Dispatcher Application)

1. Double-click the `ecomcen_dsm.exe` file in the installation directory or use the desktop shortcut.
2. Log in with the dispatcher credentials that were created in the main application.

## Troubleshooting

### Common Issues

1. **Application fails to start**:
   - Ensure all dependencies are installed correctly.
   - Check if the Visual C++ Redistributable is installed.

2. **Login issues**:
   - Verify that you're using the correct credentials.
   - If you've forgotten the admin password, contact the system administrator.

3. **Synchronization issues**:
   - Ensure both applications are running on the same network.
   - Check firewall settings to allow communication between applications.

### Getting Help

If you encounter any issues not covered in this guide, please contact the support team at support@ecomcen.mil.ng.

## Security Considerations

Ensure that:

1. The computers running the applications are secured according to security protocols.
2. Access to the applications is restricted to authorized personnel only.
3. Regular security audits are performed.
4. All data is backed up securely.
5. Strong passwords are used for all accounts.

## Updates

To update the applications:

1. Download the latest version from the official repository.
2. Follow the installation steps above.
3. Your existing data will be preserved during the update.
