# Script to download Roboto fonts for PDF generation

$fontsDir = "assets\fonts"
$fontUrls = @{
    "Roboto-Regular.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf"
    "Roboto-Bold.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf"
    "Roboto-Italic.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Italic.ttf"
    "Roboto-Light.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Light.ttf"
    "Roboto-Medium.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Medium.ttf"
}

# Create fonts directory if it doesn't exist
if (-not (Test-Path $fontsDir)) {
    Write-Host "Creating fonts directory: $fontsDir"
    New-Item -ItemType Directory -Path $fontsDir -Force | Out-Null
}

# Download each font
foreach ($font in $fontUrls.Keys) {
    $fontPath = Join-Path $fontsDir $font
    $url = $fontUrls[$font]
    
    if (-not (Test-Path $fontPath)) {
        Write-Host "Downloading $font..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $fontPath
            Write-Host "Downloaded $font successfully."
        } catch {
            Write-Host "Failed to download $font: $_"
        }
    } else {
        Write-Host "$font already exists."
    }
}

Write-Host "Font download complete."
