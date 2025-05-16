# NASDS Application Runner PowerShell Script

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "NASDS Application Runner" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Check if nasds.exe is already running
$runningProcess = Get-Process -Name "nasds" -ErrorAction SilentlyContinue

if ($runningProcess) {
    Write-Host "NASDS application is already running." -ForegroundColor Yellow
    Write-Host ""

    $answer = Read-Host "Do you want to close the running instance and start a new one? (Y/N)"

    if ($answer -eq "Y" -or $answer -eq "y") {
        Write-Host "Closing running instance..." -ForegroundColor Yellow
        Stop-Process -Name "nasds" -Force
        Write-Host ""
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "Choose which application to run:" -ForegroundColor Cyan
Write-Host "1. Main NASDS Application" -ForegroundColor White
Write-Host "2. NASDS Dispatcher Application" -ForegroundColor White
Write-Host ""
$appChoice = Read-Host "Enter your choice (1 or 2)"

if ($appChoice -eq "1") {
    Write-Host ""
    Write-Host "Starting Main NASDS Application..." -ForegroundColor Green
    Write-Host ""
    Set-Location -Path "nasds"
    flutter run -d windows
} elseif ($appChoice -eq "2") {
    Write-Host ""
    Write-Host "Starting NASDS Dispatcher Application..." -ForegroundColor Green
    Write-Host ""
    Set-Location -Path "nasds"
    flutter run -d windows --dart-define=APP_MODE=dispatcher
} else {
    Write-Host ""
    Write-Host "Invalid choice. Please run the script again and select 1 or 2." -ForegroundColor Red
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
