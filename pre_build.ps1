# Pre-build script for E-COMCEN
# This script updates copyright information with the current year

# Get the current year
$currentYear = (Get-Date).Year
Write-Host "Current year: $currentYear"

# Update Windows Runner.rc file
$windowsRcPath = "windows\runner\Runner.rc"
if (Test-Path $windowsRcPath) {
    Write-Host "Updating copyright year in $windowsRcPath..."

    # Read the file content
    $content = Get-Content $windowsRcPath -Raw

    # Replace the CURRENT_YEAR placeholder with the actual current year
    $updatedContent = $content -replace 'CURRENT_YEAR', $currentYear

    # Write the updated content back to the file
    Set-Content -Path $windowsRcPath -Value $updatedContent

    Write-Host "Windows copyright year updated successfully."
} else {
    Write-Host "Warning: Windows Runner.rc file not found at $windowsRcPath"
}

# Update macOS AppInfo.xcconfig file
$macosConfigPath = "macos\Runner\Configs\AppInfo.xcconfig"
if (Test-Path $macosConfigPath) {
    Write-Host "Updating copyright year in $macosConfigPath..."

    # Read the file content
    $content = Get-Content $macosConfigPath -Raw

    # Replace the CURRENT_YEAR variable with the actual current year
    $updatedContent = $content -replace '\$\(CURRENT_YEAR\)', $currentYear

    # Write the updated content back to the file
    Set-Content -Path $macosConfigPath -Value $updatedContent

    Write-Host "macOS copyright year updated successfully."
} else {
    Write-Host "Warning: macOS AppInfo.xcconfig file not found at $macosConfigPath"
}

Write-Host "Pre-build script completed successfully."
