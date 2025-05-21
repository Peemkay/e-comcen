# PowerShell script to update E-COMCEN logos and generate app icons

# Define paths
$projectDir = "C:\Users\chaki\Documents\Projects Augment\NASDS"
$imagesDir = "$projectDir\assets\images"
$logoPath = "$imagesDir\nas_logo.png"
$iconPath = "$imagesDir\nas_icon.png"
$downloadDir = [Environment]::GetFolderPath("Downloads")

Write-Host "E-COMCEN Logo Updater" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

# Create the images directory if it doesn't exist
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force
    Write-Host "Created directory: $imagesDir" -ForegroundColor Green
}

# Check if the downloaded logo exists
$downloadedLogo = "$downloadDir\ecomcen_logo.png"
if (Test-Path $downloadedLogo) {
    Write-Host "Found downloaded logo at: $downloadedLogo" -ForegroundColor Green
    
    # Backup existing files if they exist
    if (Test-Path $logoPath) {
        Copy-Item -Path $logoPath -Destination "$logoPath.bak" -Force
        Write-Host "Backed up existing logo to $logoPath.bak" -ForegroundColor Yellow
    }
    
    if (Test-Path $iconPath) {
        Copy-Item -Path $iconPath -Destination "$iconPath.bak" -Force
        Write-Host "Backed up existing icon to $iconPath.bak" -ForegroundColor Yellow
    }
    
    # Copy the downloaded logo to the project
    Copy-Item -Path $downloadedLogo -Destination $logoPath -Force
    Copy-Item -Path $downloadedLogo -Destination $iconPath -Force
    Write-Host "Copied logo to project directory" -ForegroundColor Green
} else {
    Write-Host "Downloaded logo not found at: $downloadedLogo" -ForegroundColor Red
    Write-Host "Please download the logo from the E-COMCEN Logo Generator first." -ForegroundColor Yellow
    Write-Host "Save it as 'ecomcen_logo.png' in your Downloads folder." -ForegroundColor Yellow
    
    # Ask if user wants to continue anyway
    $continue = Read-Host "Do you want to continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit
    }
}

# Navigate to project directory
Set-Location $projectDir

# Run flutter pub get to ensure dependencies are up to date
Write-Host "Running flutter pub get..." -ForegroundColor Cyan
& flutter pub get

# Run flutter_launcher_icons
Write-Host "Running flutter_launcher_icons..." -ForegroundColor Cyan
& flutter pub run flutter_launcher_icons

Write-Host ""
Write-Host "Logo update complete!" -ForegroundColor Green
Write-Host "The E-COMCEN logo has been implemented in the app." -ForegroundColor Green
Write-Host ""
Write-Host "You can now run the app to see the new logo in action:" -ForegroundColor Cyan
Write-Host "flutter run -d windows" -ForegroundColor Cyan
