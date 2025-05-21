# PowerShell script to generate app icons for NASDS using the Nigerian Army Signals logo

Write-Host "Generating app icons for NASDS..." -ForegroundColor Green

# Ensure we're in the right directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir"

# Check if the logo file exists
$logoPath = "assets/images/nas_logo.png"
if (-not (Test-Path $logoPath)) {
    Write-Host "Error: Logo file not found at $logoPath" -ForegroundColor Red
    Write-Host "Please ensure the Nigerian Army Signals logo is saved at this location." -ForegroundColor Yellow
    exit 1
}

# Check if the icon file exists, if not, copy from logo
$iconPath = "assets/images/nas_icon.png"
if (-not (Test-Path $iconPath)) {
    Write-Host "Icon file not found at $iconPath" -ForegroundColor Yellow
    Write-Host "Using the logo file as the icon..." -ForegroundColor Cyan
    Copy-Item -Path $logoPath -Destination $iconPath -Force

    if (Test-Path $iconPath) {
        Write-Host "Successfully created icon at $iconPath" -ForegroundColor Green
    } else {
        Write-Host "Failed to create icon" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Using existing icon at $iconPath" -ForegroundColor Green
}

# Run flutter pub get to ensure dependencies are up to date
Write-Host "Running flutter pub get..." -ForegroundColor Cyan
flutter pub get

# Run flutter_launcher_icons
Write-Host "Running flutter_launcher_icons..." -ForegroundColor Cyan
flutter pub run flutter_launcher_icons

Write-Host "Icon generation complete!" -ForegroundColor Green
Write-Host "If you encounter any issues, you may need to manually convert the SVG to PNG and run the script again."
