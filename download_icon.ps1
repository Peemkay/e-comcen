# PowerShell script to download a placeholder ICO file

# Create the directory if it doesn't exist
$resourcesDir = "windows\runner\resources"
if (-not (Test-Path $resourcesDir)) {
    Write-Host "Creating directory: $resourcesDir"
    New-Item -ItemType Directory -Path $resourcesDir -Force | Out-Null
}

# URL of a placeholder icon (Flutter's default app icon)
$iconUrl = "https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/templates/app_shared/windows.tmpl/runner/resources/app_icon.ico"
$icoPath = "windows\runner\resources\app_icon.ico"

Write-Host "Downloading placeholder icon from GitHub..."
try {
    Invoke-WebRequest -Uri $iconUrl -OutFile $icoPath
    Write-Host "Icon downloaded successfully to: $icoPath"
    
    # Verify the file exists and show its details
    if (Test-Path $icoPath) {
        $fileInfo = Get-Item $icoPath
        Write-Host "File size: $($fileInfo.Length) bytes"
        Write-Host "Last modified: $($fileInfo.LastWriteTime)"
    } else {
        Write-Host "Error: File was not created!"
    }
} catch {
    Write-Host "Error downloading icon: $_"
}

Write-Host "`nNow try running:"
Write-Host "flutter run -d windows"
