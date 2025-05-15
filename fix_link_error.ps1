# Script to fix LINK1168 error (cannot open file for writing)

# Check for running processes that might be locking files
Write-Host "Checking for processes that might be locking files..."
$processes = Get-Process | Where-Object { $_.ProcessName -match "flutter|dart|msvc|cl|link|cmake|ninja|nasds" }

if ($processes) {
    Write-Host "Found processes that might be locking files:"
    $processes | ForEach-Object {
        Write-Host "  $($_.ProcessName) (PID: $($_.Id))"
    }
    
    $confirmation = Read-Host "Do you want to terminate these processes? (y/n)"
    if ($confirmation -eq 'y') {
        $processes | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force
                Write-Host "Terminated process: $($_.ProcessName) (PID: $($_.Id))"
            } catch {
                Write-Host "Failed to terminate process: $($_.ProcessName) (PID: $($_.Id))"
            }
        }
    }
}

# Clean build directories
Write-Host "Cleaning build directories..."
$buildDirs = @(
    "build\windows",
    ".dart_tool",
    "windows\flutter\ephemeral"
)

foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force
            Write-Host "Removed directory: $dir"
        } catch {
            Write-Host "Failed to remove directory: $dir"
            Write-Host "Error: $_"
            
            # Try to identify locked files
            $lockedFiles = Get-ChildItem -Path $dir -Recurse -File | ForEach-Object {
                try {
                    $stream = [System.IO.File]::Open($_.FullName, 'Open', 'Read', 'None')
                    $stream.Close()
                    $stream.Dispose()
                } catch {
                    $_
                }
            }
            
            if ($lockedFiles) {
                Write-Host "Found locked files:"
                $lockedFiles | ForEach-Object {
                    Write-Host "  $($_.TargetObject)"
                }
            }
        }
    }
}

# Create a temporary directory with write permissions
$tempDir = "windows\temp_build"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force
    Write-Host "Created temporary build directory: $tempDir"
}

# Set full permissions on the temp directory
$acl = Get-Acl $tempDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.SetAccessRule($accessRule)
Set-Acl $tempDir $acl
Write-Host "Set full permissions on temporary build directory"

# Modify the CMakeLists.txt to use the temporary directory
$cmakeListsPath = "windows\CMakeLists.txt"
$cmakeContent = Get-Content $cmakeListsPath -Raw

# Add a line to set the build directory to the temporary directory
if (-not $cmakeContent.Contains("set(CMAKE_BINARY_DIR")) {
    $insertPoint = "# Define build configuration option."
    $tempDirConfig = @"
# Set build directory to a temporary location with full permissions
set(CMAKE_BINARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/temp_build")

"@
    $cmakeContent = $cmakeContent -replace [regex]::Escape($insertPoint), ($tempDirConfig + $insertPoint)
    Set-Content -Path $cmakeListsPath -Value $cmakeContent
    Write-Host "Modified CMakeLists.txt to use temporary build directory"
}

Write-Host "Link error fix complete. Try building the Windows app now with: flutter build windows --debug"
