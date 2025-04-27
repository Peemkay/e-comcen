# Check if the icon file exists
$iconPath = "windows\runner\resources\app_icon.ico"
$fullPath = Join-Path -Path (Get-Location) -ChildPath $iconPath

Write-Host "Checking for icon file at: $fullPath"

if (Test-Path $iconPath) {
    Write-Host "Icon file exists!"
    $fileInfo = Get-Item $iconPath
    Write-Host "File size: $($fileInfo.Length) bytes"
    Write-Host "Last modified: $($fileInfo.LastWriteTime)"
} else {
    Write-Host "Icon file does not exist!"
    
    # Check if the directory exists
    $dirPath = "windows\runner\resources"
    if (Test-Path $dirPath) {
        Write-Host "Directory exists: $dirPath"
        Write-Host "Files in directory:"
        Get-ChildItem $dirPath | ForEach-Object { Write-Host "  - $($_.Name)" }
    } else {
        Write-Host "Directory does not exist: $dirPath"
    }
}

# Check the Runner.rc file
$rcPath = "windows\runner\Runner.rc"
if (Test-Path $rcPath) {
    Write-Host "`nContents of Runner.rc file (relevant part):"
    $content = Get-Content $rcPath
    $iconLine = $content | Select-String -Pattern "app_icon.ico"
    if ($iconLine) {
        $lineNumber = $iconLine.LineNumber
        $startLine = [Math]::Max(1, $lineNumber - 5)
        $endLine = [Math]::Min($content.Count, $lineNumber + 5)
        
        for ($i = $startLine; $i -le $endLine; $i++) {
            if ($i -eq $lineNumber) {
                Write-Host "$i: $($content[$i-1]) <-- This line references the icon file"
            } else {
                Write-Host "$i: $($content[$i-1])"
            }
        }
    } else {
        Write-Host "Could not find reference to app_icon.ico in Runner.rc"
    }
} else {
    Write-Host "Runner.rc file not found at: $rcPath"
}
