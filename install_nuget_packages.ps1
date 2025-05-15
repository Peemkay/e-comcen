# Script to manually download and install required NuGet packages for Flutter Windows build

# Create a directory for NuGet packages
$nugetPackagesDir = "windows\nuget_packages"
if (-not (Test-Path $nugetPackagesDir)) {
    New-Item -ItemType Directory -Path $nugetPackagesDir -Force
    Write-Host "Created directory: $nugetPackagesDir"
}

# Download NuGet.exe if not already downloaded
$nugetExePath = "C:\Users\chaki\.nuget\nuget.exe"
if (-not (Test-Path $nugetExePath)) {
    $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $nugetDir = "C:\Users\chaki\.nuget"
    
    if (-not (Test-Path $nugetDir)) {
        New-Item -ItemType Directory -Path $nugetDir -Force
        Write-Host "Created directory: $nugetDir"
    }
    
    Write-Host "Downloading NuGet.exe..."
    Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetExePath
    Write-Host "Downloaded NuGet.exe to: $nugetExePath"
}

# Install required NuGet packages
$packages = @(
    "Microsoft.Windows.CppWinRT -Version 2.0.220929.3",
    "Microsoft.Windows.SDK.BuildTools -Version 10.0.22621.755",
    "Microsoft.WindowsAppSDK -Version 1.3.230602002"
)

foreach ($package in $packages) {
    Write-Host "Installing NuGet package: $package"
    & $nugetExePath install $package -OutputDirectory $nugetPackagesDir
}

# Create a file to help Flutter find the NuGet packages
$nugetConfigPath = "windows\nuget.config"
$nugetConfigContent = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="local" value="$nugetPackagesDir" />
  </packageSources>
  <packageRestore>
    <add key="enabled" value="True" />
    <add key="automatic" value="True" />
  </packageRestore>
  <bindingRedirects>
    <add key="skip" value="False" />
  </bindingRedirects>
  <packageManagement>
    <add key="format" value="0" />
    <add key="disabled" value="False" />
  </packageManagement>
</configuration>
"@

Set-Content -Path $nugetConfigPath -Value $nugetConfigContent
Write-Host "Created NuGet configuration file: $nugetConfigPath"

Write-Host "NuGet packages installation complete. Try building the Windows app now."
