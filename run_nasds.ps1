# Script to run the NASDS application

$exePath = "build\windows\x64\runner\Debug\nasds.exe"

if (Test-Path $exePath) {
    Write-Host "Starting NASDS application..."
    Start-Process -FilePath $exePath
} else {
    Write-Host "NASDS executable not found at: $exePath"
    Write-Host "Please build the application first with: flutter build windows --debug"
}
