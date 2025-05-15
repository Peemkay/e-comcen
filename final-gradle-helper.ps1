# Gradle Helper PowerShell Script
# This script helps with running Gradle commands when Gradle is not in the PATH

# Set JAVA_HOME to the correct location
$javaHome = "C:\Program Files\Java\jdk-19"
if (Test-Path $javaHome) {
    $env:JAVA_HOME = $javaHome
    Write-Host "Set JAVA_HOME to $javaHome" -ForegroundColor Green
} else {
    Write-Host "Warning: Java directory $javaHome not found" -ForegroundColor Yellow
    # Try to find Java installation
    $javaDir = Get-ChildItem "C:\Program Files\Java" -Directory | Select-Object -First 1
    if ($javaDir) {
        $env:JAVA_HOME = $javaDir.FullName
        Write-Host "Set JAVA_HOME to $($javaDir.FullName)" -ForegroundColor Green
    }
}

# Use the known Gradle installation path directly
$gradleExe = "C:\Users\chaki\.gradle\wrapper\dists\gradle-8.3-all\14a5icgnf00j9oh8g6q33b3p0\gradle-8.3\bin\gradle.bat"

if (Test-Path $gradleExe) {
    Write-Host "Using Gradle installation at $gradleExe" -ForegroundColor Green
    
    # Execute Gradle command with --no-daemon and --offline flags to avoid network issues
    $command = "& '$gradleExe' --no-daemon --offline $args"
    Write-Host "Executing: $command" -ForegroundColor Cyan
    Invoke-Expression $command
} else {
    Write-Host "Gradle installation not found at $gradleExe" -ForegroundColor Red
    Write-Host "Please make sure you have Gradle installed" -ForegroundColor Yellow
    exit 1
}
