# Build and Run NASDS on Windows
# This script builds the NASDS application for Windows and runs it

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to display colored messages
function Write-ColoredOutput {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

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

# Function to clean the project
function Clean-Project {
    Write-ColoredOutput "Cleaning the project..." -ForegroundColor Cyan
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-ColoredOutput "Failed to clean the project. Error code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    Write-ColoredOutput "Project cleaned successfully." -ForegroundColor Green
}

# Function to get dependencies
function Get-Dependencies {
    Write-ColoredOutput "Getting Flutter dependencies..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-ColoredOutput "Failed to get dependencies. Error code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    Write-ColoredOutput "Dependencies retrieved successfully." -ForegroundColor Green
}

# Function to build the Windows application
function Build-WindowsApp {
    Write-ColoredOutput "Building Windows application..." -ForegroundColor Cyan
    flutter build windows --debug
    if ($LASTEXITCODE -ne 0) {
        Write-ColoredOutput "Failed to build Windows application. Error code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    Write-ColoredOutput "Windows application built successfully." -ForegroundColor Green
}

# Function to run the Windows application
function Run-WindowsApp {
    $exePath = "build\windows\x64\runner\Debug\nasds.exe"
    
    if (Test-Path $exePath) {
        Write-ColoredOutput "Starting NASDS application..." -ForegroundColor Cyan
        Start-Process -FilePath $exePath
        Write-ColoredOutput "NASDS application started." -ForegroundColor Green
    } else {
        Write-ColoredOutput "NASDS executable not found at: $exePath" -ForegroundColor Red
        Write-ColoredOutput "Build may have failed or the path is incorrect." -ForegroundColor Red
        exit 1
    }
}

# Main script execution
Write-ColoredOutput "NASDS Windows Build and Run" -ForegroundColor Cyan
Write-ColoredOutput "==========================" -ForegroundColor Cyan

# Check if Flutter is installed
if (-not (Test-FlutterInstalled)) {
    Write-ColoredOutput "Flutter is not installed or not in PATH. Please install Flutter and try again." -ForegroundColor Red
    exit 1
}

# Execute the build and run process
try {
    # Clean the project
    Clean-Project
    
    # Get dependencies
    Get-Dependencies
    
    # Build Windows application
    Build-WindowsApp
    
    # Run the application
    Run-WindowsApp
    
    Write-ColoredOutput "Build and run process completed successfully!" -ForegroundColor Green
} catch {
    Write-ColoredOutput "An error occurred: $_" -ForegroundColor Red
    exit 1
}
