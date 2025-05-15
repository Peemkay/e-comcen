# Script to fix Windows build issues for Flutter

# 1. Clean the build directory
Write-Host "Cleaning build directory..."
flutter clean

# 2. Delete the ephemeral directory which might contain corrupted files
$ephemeralDir = "windows\flutter\ephemeral"
if (Test-Path $ephemeralDir) {
    Write-Host "Removing ephemeral directory..."
    Remove-Item -Path $ephemeralDir -Recurse -Force
}

# 3. Disable problematic plugins temporarily
Write-Host "Temporarily disabling problematic plugins..."
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

# Comment out printing plugin if it's causing issues
$pubspecContent = $pubspecContent -replace "printing: \^5.11.1", "# printing: ^5.11.1  # Temporarily disabled due to Windows build issues"

# Save the modified pubspec
Set-Content -Path $pubspecPath -Value $pubspecContent

# 4. Get Flutter dependencies
Write-Host "Getting Flutter dependencies..."
flutter pub get

# 5. Configure Windows build with specific options
Write-Host "Configuring Windows build..."
$cmakeListsPath = "windows\CMakeLists.txt"
$cmakeContent = Get-Content $cmakeListsPath -Raw

# Add additional configuration for Windows build
if (-not $cmakeContent.Contains("set(ADDITIONAL_WINDOWS_BUILD_FLAGS")) {
    $insertPoint = "# Define build configuration option."
    $additionalConfig = @"
# Additional Windows build configuration to fix linker issues
set(ADDITIONAL_WINDOWS_BUILD_FLAGS "/ignore:4099" CACHE STRING "Additional flags for Windows builds")
set(CMAKE_EXE_LINKER_FLAGS "\${CMAKE_EXE_LINKER_FLAGS} \${ADDITIONAL_WINDOWS_BUILD_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS "\${CMAKE_SHARED_LINKER_FLAGS} \${ADDITIONAL_WINDOWS_BUILD_FLAGS}")

"@
    $cmakeContent = $cmakeContent -replace [regex]::Escape($insertPoint), ($additionalConfig + $insertPoint)
    Set-Content -Path $cmakeListsPath -Value $cmakeContent
}

# 6. Create a local.properties file with SDK location
$localPropertiesPath = "android\local.properties"
if (-not (Test-Path $localPropertiesPath)) {
    Write-Host "Creating local.properties file..."
    $androidSdkPath = [Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT", "User")
    if (-not $androidSdkPath) {
        $androidSdkPath = [Environment]::GetEnvironmentVariable("ANDROID_HOME", "User")
    }
    if ($androidSdkPath) {
        $androidSdkPath = $androidSdkPath -replace "\\", "\\"
        Set-Content -Path $localPropertiesPath -Value "sdk.dir=$androidSdkPath"
    }
}

Write-Host "Setup complete. Try building the Windows app with: flutter build windows"
