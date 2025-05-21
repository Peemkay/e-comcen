# PowerShell script to save the Nigerian Army Signals logo and generate app icons

# Define paths
$projectDir = "C:\Users\chaki\Documents\Projects Augment\NASDS"
$imagesDir = "$projectDir\assets\images"
$logoPath = "$imagesDir\nas_logo.png"
$iconPath = "$imagesDir\nas_icon.png"
$tempLogoPath = "$env:TEMP\nas_logo_temp.png"

# Create the images directory if it doesn't exist
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force
    Write-Host "Created directory: $imagesDir" -ForegroundColor Green
}

# Check if the logo file already exists
if (Test-Path $logoPath) {
    Write-Host "Logo file already exists at: $logoPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Keeping existing logo file." -ForegroundColor Cyan
    } else {
        # Backup existing file
        Copy-Item -Path $logoPath -Destination "$logoPath.bak" -Force
        Write-Host "Backed up existing logo to $logoPath.bak" -ForegroundColor Cyan
        
        # Instructions for saving the new logo
        Write-Host "Please save the Nigerian Army Signals logo to: $logoPath" -ForegroundColor Green
        Write-Host "You can right-click on the image in the chat and select 'Save image as...'" -ForegroundColor Green
        
        # Wait for user to save the file
        Read-Host "Press Enter after you've saved the logo"
    }
} else {
    # Instructions for saving the new logo
    Write-Host "Please save the Nigerian Army Signals logo to: $logoPath" -ForegroundColor Green
    Write-Host "You can right-click on the image in the chat and select 'Save image as...'" -ForegroundColor Green
    
    # Wait for user to save the file
    Read-Host "Press Enter after you've saved the logo"
}

# Check if the icon file already exists
if (Test-Path $iconPath) {
    Write-Host "Icon file already exists at: $iconPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "Keeping existing icon file." -ForegroundColor Cyan
    } else {
        # Backup existing file
        Copy-Item -Path $iconPath -Destination "$iconPath.bak" -Force
        Write-Host "Backed up existing icon to $iconPath.bak" -ForegroundColor Cyan
        
        # Copy logo to icon if logo exists
        if (Test-Path $logoPath) {
            Copy-Item -Path $logoPath -Destination $iconPath -Force
            Write-Host "Copied logo to icon location." -ForegroundColor Green
        } else {
            # Instructions for saving the new icon
            Write-Host "Please save the Nigerian Army Signals icon to: $iconPath" -ForegroundColor Green
            Write-Host "You can right-click on the image in the chat and select 'Save image as...'" -ForegroundColor Green
            
            # Wait for user to save the file
            Read-Host "Press Enter after you've saved the icon"
        }
    }
} else {
    # Copy logo to icon if logo exists
    if (Test-Path $logoPath) {
        Copy-Item -Path $logoPath -Destination $iconPath -Force
        Write-Host "Copied logo to icon location." -ForegroundColor Green
    } else {
        # Instructions for saving the new icon
        Write-Host "Please save the Nigerian Army Signals icon to: $iconPath" -ForegroundColor Green
        Write-Host "You can right-click on the image in the chat and select 'Save image as...'" -ForegroundColor Green
        
        # Wait for user to save the file
        Read-Host "Press Enter after you've saved the icon"
    }
}

# Verify that the files exist
if ((Test-Path $logoPath) -and (Test-Path $iconPath)) {
    Write-Host "Logo and icon files are in place." -ForegroundColor Green
    
    # Run flutter pub get to ensure dependencies are up to date
    Write-Host "Running flutter pub get..." -ForegroundColor Cyan
    Set-Location $projectDir
    & flutter pub get
    
    # Run flutter_launcher_icons
    Write-Host "Running flutter_launcher_icons..." -ForegroundColor Cyan
    & flutter pub run flutter_launcher_icons
    
    Write-Host "Icon generation complete!" -ForegroundColor Green
    Write-Host "The Nigerian Army Signals logo has been implemented in the app." -ForegroundColor Green
} else {
    Write-Host "Error: Logo or icon files are missing." -ForegroundColor Red
    Write-Host "Please make sure both files exist before generating app icons." -ForegroundColor Red
}

Write-Host "Script completed. You can now run the app to see the logo in action." -ForegroundColor Green
Write-Host "Run: flutter run -d windows" -ForegroundColor Cyan
