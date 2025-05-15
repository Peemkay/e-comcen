# Script to download NuGet.exe and place it in the correct location
$nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$nugetPath = "C:\Users\chaki\.nuget"

# Create directory if it doesn't exist
if (-not (Test-Path $nugetPath)) {
    New-Item -ItemType Directory -Path $nugetPath -Force
    Write-Host "Created directory: $nugetPath"
}

# Download NuGet.exe
$nugetExePath = Join-Path $nugetPath "nuget.exe"
Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetExePath
Write-Host "Downloaded NuGet.exe to: $nugetExePath"

# Add to PATH if not already there
$envPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $envPath.Contains($nugetPath)) {
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$nugetPath", "User")
    Write-Host "Added $nugetPath to PATH environment variable"
}

Write-Host "NuGet.exe has been downloaded and configured successfully."
