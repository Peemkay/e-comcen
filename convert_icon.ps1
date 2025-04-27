# PowerShell script to convert SVG to ICO using ImageMagick
# Note: This requires ImageMagick to be installed on the system

# Check if ImageMagick is installed
try {
    $magickPath = (Get-Command magick -ErrorAction Stop).Source
    Write-Host "ImageMagick found at: $magickPath"
} catch {
    Write-Host "ImageMagick not found. Please install ImageMagick and make sure it's in your PATH."
    Write-Host "You can download it from: https://imagemagick.org/script/download.php"
    exit 1
}

# Paths
$svgPath = "windows\runner\resources\nasds_icon.svg"
$icoPath = "windows\runner\resources\app_icon.ico"

# Create temporary directory for PNG files
$tempDir = "temp_icons"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Sizes for the icon (Windows standard sizes)
$sizes = @(16, 24, 32, 48, 64, 128, 256)

# Convert SVG to multiple PNG sizes
foreach ($size in $sizes) {
    $outputPng = "$tempDir\icon_$size.png"
    Write-Host "Converting SVG to $size x $size PNG..."
    magick convert -background none -size "$($size)x$($size)" $svgPath $outputPng
}

# Combine PNGs into ICO file
Write-Host "Creating ICO file..."
$pngFiles = Get-ChildItem -Path $tempDir -Filter "icon_*.png" | ForEach-Object { $_.FullName }
magick convert $pngFiles $icoPath

# Clean up temporary files
Write-Host "Cleaning up temporary files..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Icon conversion complete. New icon saved to: $icoPath"
