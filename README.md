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

## Setup

### Prerequisites
- Flutter SDK
- Windows development environment

### Running the Main Application
1. Navigate to the `nasds` directory
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d windows` to run the application on Windows

### Running the Dispatcher Application
1. Navigate to the `ecomcen_dsm` directory
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d windows` to run the application on Windows

## Project Structure

- `nasds/` - Contains the main E-COMCEN application
- `ecomcen_dsm/` - Contains the E-COMCEN-DSM application for dispatchers

## Security

This application is classified as SECRET and implements real-time security features to protect sensitive information.
