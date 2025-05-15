# NASDS Windows Installer Creation Script
# This script creates a Windows installer package for the NASDS application

# Configuration
$appName = "NASDS"
$appDescription = "Electronic Communications Center (E-COMCEN)"
$outputDir = "installer"

# Function to check if Flutter is installed
function Test-FlutterInstalled {
    try {
        $flutterVersion = flutter --version
        return $true
    }
    catch {
        return $false
    }
}

# Function to create the MSIX installer package
function Create-MsixPackage {
    Write-Host "Creating MSIX installer package..." -ForegroundColor Cyan
    
    # Get Flutter dependencies
    Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
    flutter pub get
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory | Out-Null
    }
    
    # Build MSIX package
    Write-Host "Building MSIX package..." -ForegroundColor Cyan
    flutter pub run msix:create
    
    # Check if MSIX package was created
    $msixFiles = Get-ChildItem -Path "build\windows\x64\runner\Release" -Filter "*.msix"
    
    if ($msixFiles.Count -gt 0) {
        # Copy MSIX package to output directory
        foreach ($msixFile in $msixFiles) {
            $destPath = Join-Path -Path $outputDir -ChildPath $msixFile.Name
            Copy-Item -Path $msixFile.FullName -Destination $destPath -Force
            Write-Host "MSIX package created: $destPath" -ForegroundColor Green
        }
        return $true
    }
    else {
        Write-Host "Failed to create MSIX package." -ForegroundColor Red
        return $false
    }
}

# Main script execution
Write-Host "NASDS Windows Installer Creation" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check if Flutter is installed
if (-not (Test-FlutterInstalled)) {
    Write-Host "Flutter is not installed or not in PATH. Please install Flutter and try again." -ForegroundColor Red
    exit 1
}

# Create MSIX package
$packageSuccess = Create-MsixPackage
if (-not $packageSuccess) {
    Write-Host "Failed to create the installer package. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Installer creation complete!" -ForegroundColor Green
Write-Host "You can find the installer package in the '$outputDir' directory." -ForegroundColor Green
