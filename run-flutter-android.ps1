# Script to run Flutter app on Android with better feedback
param (
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to display messages with timestamp
function Write-TimeLog {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Start the script
Write-TimeLog "Starting Flutter Android app deployment" -Color Cyan
Write-TimeLog "Current directory: $(Get-Location)" -Color Gray

# Check if this is a Flutter project
if (-not (Test-Path "pubspec.yaml")) {
    Write-TimeLog "Error: pubspec.yaml not found. Are you in a Flutter project directory?" -Color Red
    exit 1
}

# Clean the project if requested
if ($Clean) {
    Write-TimeLog "Cleaning Flutter project..." -Color Yellow
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-TimeLog "Error: Flutter clean failed with exit code $LASTEXITCODE" -Color Red
        exit $LASTEXITCODE
    }
    Write-TimeLog "Flutter project cleaned successfully" -Color Green
}

# Check for connected devices
Write-TimeLog "Checking for connected devices..." -Color Yellow
$devices = flutter devices
if ($LASTEXITCODE -ne 0) {
    Write-TimeLog "Error: Failed to list Flutter devices" -Color Red
    exit $LASTEXITCODE
}

Write-TimeLog "Available devices:" -Color Cyan
$devices | ForEach-Object { Write-Host "  $_" }

# Check if Android emulator is in the list
if ($devices -match "emulator-\d+") {
    $emulatorId = $devices -split "\s+" | Select-String "emulator-\d+" | Select-Object -First 1
    Write-TimeLog "Found Android emulator: $emulatorId" -Color Green
} else {
    Write-TimeLog "No Android emulator found in the device list" -Color Red
    Write-TimeLog "Please make sure the emulator is running" -Color Yellow
    exit 1
}

# Set JAVA_HOME to the correct location
$javaHome = "C:\Program Files\Java\jdk-19"
if (Test-Path $javaHome) {
    $env:JAVA_HOME = $javaHome
    Write-TimeLog "Set JAVA_HOME to $javaHome" -Color Green
} else {
    Write-TimeLog "Warning: Java directory $javaHome not found" -Color Yellow
    # Try to find Java installation
    $javaDir = Get-ChildItem "C:\Program Files\Java" -Directory | Select-Object -First 1
    if ($javaDir) {
        $env:JAVA_HOME = $javaDir.FullName
        Write-TimeLog "Set JAVA_HOME to $($javaDir.FullName)" -Color Green
    }
}

# Run the Flutter app
Write-TimeLog "Running Flutter app on Android emulator ($emulatorId)..." -Color Cyan
Write-TimeLog "This may take several minutes for the first build" -Color Yellow

# Build the command
$flutterCommand = "flutter run -d $emulatorId"
if ($Verbose) {
    $flutterCommand += " -v"
}

Write-TimeLog "Executing: $flutterCommand" -Color Gray
Invoke-Expression $flutterCommand

# Check the result
if ($LASTEXITCODE -eq 0) {
    Write-TimeLog "App successfully launched on Android emulator!" -Color Green
} else {
    Write-TimeLog "Failed to launch app. Exit code: $LASTEXITCODE" -Color Red
}
