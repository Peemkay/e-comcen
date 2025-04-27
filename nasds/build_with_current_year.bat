@echo off
echo Running pre-build script to update copyright year...
powershell -ExecutionPolicy Bypass -File pre_build.ps1

echo Building Flutter app...
flutter build windows

echo Build completed successfully!
