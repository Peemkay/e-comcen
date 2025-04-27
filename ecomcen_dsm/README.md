# E-COMCEN Dispatch Service Manager (E-COMCEN-DSM)

This is the dispatcher application for the E-COMCEN system. It is used by dispatchers to update the status of dispatches and synchronize with the main E-COMCEN application.

## Features

- Dispatcher login with role-based authentication
- View assigned dispatches
- Update dispatch status
- Track dispatch progress
- Synchronize with main E-COMCEN application

## Setup

1. Make sure the main E-COMCEN application is set up correctly
2. Run `flutter pub get` to install dependencies
3. Run `flutter run -d windows` to run the application on Windows

## Directory Structure

- `lib/` - Contains the Dart code for the application
- `assets/` - Contains assets like images, translations, and fonts
  - `assets/images/` - Contains images used in the application
  - `assets/translations/` - Contains translation files
  - `assets/fonts/` - Contains font files

## Dependencies

This application depends on the main E-COMCEN application for shared models and services.
