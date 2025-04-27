# PowerShell script to check and fix the icon issue

# Create the directory if it doesn't exist
$resourcesDir = "windows\runner\resources"
if (-not (Test-Path $resourcesDir)) {
    Write-Host "Creating directory: $resourcesDir"
    New-Item -ItemType Directory -Path $resourcesDir -Force | Out-Null
}

# Check if the SVG file exists
$svgPath = "windows\runner\resources\nasds_icon_simple.svg"
if (Test-Path $svgPath) {
    Write-Host "SVG file exists at: $svgPath"
} else {
    Write-Host "SVG file not found, checking parent directory..."
    $parentSvgPath = "..\windows\runner\resources\nasds_icon_simple.svg"
    if (Test-Path $parentSvgPath) {
        Write-Host "Found SVG in parent directory, copying..."
        Copy-Item $parentSvgPath $svgPath
    } else {
        Write-Host "SVG file not found in parent directory either!"
    }
}

# Check if the ICO file exists
$icoPath = "windows\runner\resources\app_icon.ico"
if (Test-Path $icoPath) {
    Write-Host "ICO file exists at: $icoPath"
    $fileInfo = Get-Item $icoPath
    Write-Host "File size: $($fileInfo.Length) bytes"
    Write-Host "Last modified: $($fileInfo.LastWriteTime)"
} else {
    Write-Host "ICO file not found at: $icoPath"
    Write-Host "Please create the ICO file using an online converter:"
    Write-Host "1. Go to https://convertio.co/svg-ico/"
    Write-Host "2. Upload the SVG file from $svgPath"
    Write-Host "3. Configure the conversion to include these sizes: 16x16, 32x32, 48x48, 64x64, 128x128, 256x256"
    Write-Host "4. Download the resulting ICO file"
    Write-Host "5. Save it as app_icon.ico in the $resourcesDir directory"
}

# List files in the resources directory
Write-Host "`nFiles in $resourcesDir directory:"
if (Test-Path $resourcesDir) {
    $files = Get-ChildItem $resourcesDir
    if ($files.Count -eq 0) {
        Write-Host "  (No files found)"
    } else {
        foreach ($file in $files) {
            Write-Host "  - $($file.Name) ($($file.Length) bytes)"
        }
    }
} else {
    Write-Host "  (Directory does not exist)"
}

Write-Host "`nAfter creating the ICO file, run:"
Write-Host "flutter clean"
Write-Host "flutter build windows"
