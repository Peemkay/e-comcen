# NASDS Windows Setup Script
# This script builds the NASDS application for Windows and creates shortcuts

# Configuration
$appName = "NASDS"
$appDescription = "Electronic Communications Center (E-COMCEN)"
$exePath = "build\windows\x64\runner\Debug\nasds.exe"
$iconPath = "assets\images\nasds_logo.png"
$desktopShortcut = $true
$startMenuShortcut = $true

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

# Function to build the application
function Build-NasdsApp {
    Write-Host "Building NASDS application for Windows..." -ForegroundColor Cyan
    
    # Get Flutter dependencies
    Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
    flutter pub get
    
    # Build Windows application
    Write-Host "Building Windows application..." -ForegroundColor Cyan
    flutter build windows --debug
    
    # Check if build was successful
    if (Test-Path $exePath) {
        Write-Host "Build successful!" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Build failed. Executable not found at: $exePath" -ForegroundColor Red
        return $false
    }
}

# Function to create a desktop shortcut
function Create-DesktopShortcut {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path -Path $desktopPath -ChildPath "$appName.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = (Resolve-Path $exePath).Path
    $Shortcut.Description = $appDescription
    $Shortcut.WorkingDirectory = (Get-Location).Path
    # If we had a proper icon file, we would set it here
    # $Shortcut.IconLocation = (Resolve-Path $iconPath).Path
    $Shortcut.Save()
    
    Write-Host "Desktop shortcut created at: $shortcutPath" -ForegroundColor Green
}

# Function to create a Start Menu shortcut
function Create-StartMenuShortcut {
    $startMenuPath = [Environment]::GetFolderPath("StartMenu")
    $programsPath = Join-Path -Path $startMenuPath -ChildPath "Programs"
    $appFolderPath = Join-Path -Path $programsPath -ChildPath $appName
    
    # Create app folder in Start Menu if it doesn't exist
    if (-not (Test-Path $appFolderPath)) {
        New-Item -Path $appFolderPath -ItemType Directory | Out-Null
    }
    
    $shortcutPath = Join-Path -Path $appFolderPath -ChildPath "$appName.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = (Resolve-Path $exePath).Path
    $Shortcut.Description = $appDescription
    $Shortcut.WorkingDirectory = (Get-Location).Path
    # If we had a proper icon file, we would set it here
    # $Shortcut.IconLocation = (Resolve-Path $iconPath).Path
    $Shortcut.Save()
    
    Write-Host "Start Menu shortcut created at: $shortcutPath" -ForegroundColor Green
}

# Main script execution
Write-Host "NASDS Windows Setup" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Check if Flutter is installed
if (-not (Test-FlutterInstalled)) {
    Write-Host "Flutter is not installed or not in PATH. Please install Flutter and try again." -ForegroundColor Red
    exit 1
}

# Build the application
$buildSuccess = Build-NasdsApp
if (-not $buildSuccess) {
    Write-Host "Failed to build the application. Exiting." -ForegroundColor Red
    exit 1
}

# Create shortcuts
if ($desktopShortcut) {
    Create-DesktopShortcut
}

if ($startMenuShortcut) {
    Create-StartMenuShortcut
}

# Run the application
Write-Host "Starting NASDS application..." -ForegroundColor Cyan
Start-Process -FilePath $exePath

Write-Host "Setup complete!" -ForegroundColor Green
