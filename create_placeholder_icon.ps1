# PowerShell script to create a placeholder ICO file using .NET

# Create the directory if it doesn't exist
$resourcesDir = "nasds\windows\runner\resources"
if (-not (Test-Path $resourcesDir)) {
    Write-Host "Creating directory: $resourcesDir"
    New-Item -ItemType Directory -Path $resourcesDir -Force | Out-Null
}

$icoPath = "nasds\windows\runner\resources\app_icon.ico"

# Create a simple 16x16 bitmap and save it as ICO
Add-Type -AssemblyName System.Drawing

try {
    # Create a bitmap
    $bitmap = New-Object System.Drawing.Bitmap 16, 16
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Fill with a color
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 32, 91)) # #00205B (NASDS blue)
    
    # Draw a simple shape
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gold, 2)
    $graphics.DrawRectangle($pen, 4, 4, 8, 8)
    
    # Save as ICO
    $bitmap.Save($icoPath, [System.Drawing.Imaging.ImageFormat]::Icon)
    
    $graphics.Dispose()
    $bitmap.Dispose()
    
    Write-Host "Created placeholder icon at: $icoPath"
    
    # Verify the file exists
    if (Test-Path $icoPath) {
        $fileInfo = Get-Item $icoPath
        Write-Host "File size: $($fileInfo.Length) bytes"
        Write-Host "Last modified: $($fileInfo.LastWriteTime)"
    } else {
        Write-Host "Error: File was not created!"
    }
} catch {
    Write-Host "Error creating icon: $_"
}

Write-Host "`nNow try running:"
Write-Host "cd nasds && flutter run -d windows"
