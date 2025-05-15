$content = @'
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

# Try to find an existing Gradle installation first
Write-Host "Looking for existing Gradle installations..." -ForegroundColor Cyan

# Define paths to search for existing Gradle installations
$gradleExe = $null
$gradleDirs = @(
    "$env:USERPROFILE\.gradle\wrapper\dists\gradle-8.3-all",
    "$env:USERPROFILE\.gradle\wrapper\dists\gradle-8.7-all",
    "$env:USERPROFILE\.gradle\wrapper\dists"
)

    foreach ($gradleDir in $gradleDirs) {
        if (Test-Path $gradleDir) {
            Write-Host "Searching in $gradleDir..." -ForegroundColor Cyan

            # First try to find gradle.bat directly
            $gradleFiles = Get-ChildItem -Path $gradleDir -Filter "gradle.bat" -Recurse -ErrorAction SilentlyContinue
            if ($gradleFiles -and $gradleFiles.Count -gt 0) {
                $gradleExe = $gradleFiles[0].FullName
                Write-Host "Found existing Gradle installation at $gradleExe" -ForegroundColor Green
                break
            }

            # If not found, look for bin directories
            $binDirs = Get-ChildItem -Path $gradleDir -Filter "bin" -Directory -Recurse -ErrorAction SilentlyContinue
            foreach ($binDir in $binDirs) {
                $gradleFiles = Get-ChildItem -Path $binDir.FullName -Filter "gradle.bat" -ErrorAction SilentlyContinue
                if ($gradleFiles -and $gradleFiles.Count -gt 0) {
                    $gradleExe = $gradleFiles[0].FullName
                    Write-Host "Found existing Gradle installation at $gradleExe" -ForegroundColor Green
                    break
                }
            }

            if ($gradleExe) { break }
        }
    }
}

# Execute Gradle command
if ($gradleExe) {
    $command = "& '$gradleExe' $args"
    Write-Host "Executing: $command" -ForegroundColor Cyan
    Invoke-Expression $command
} else {
    Write-Host "No Gradle installation or wrapper found" -ForegroundColor Red
    Write-Host "Please make sure you have Gradle installed or run this script from a directory containing a Gradle project" -ForegroundColor Yellow
    exit 1
}
'@

# Update the gradle-helper.ps1 file
Set-Content -Path "C:\Users\chaki\Scripts\gradle-helper.ps1" -Value $content

Write-Host "gradle-helper.ps1 has been updated" -ForegroundColor Green
