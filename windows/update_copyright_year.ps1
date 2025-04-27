# PowerShell script to update copyright year in Runner.rc file
# This script should be run as part of the build process

# Get the current year
$currentYear = (Get-Date).Year

# Path to the Runner.rc file
$rcFilePath = "runner\Runner.rc"

# Check if the file exists
if (Test-Path $rcFilePath) {
    Write-Host "Updating copyright year in $rcFilePath to $currentYear..."
    
    # Read the file content
    $content = Get-Content $rcFilePath -Raw
    
    # Replace the copyright year with the current year using regex
    # This pattern looks for the copyright line and replaces just the year part
    $updatedContent = $content -replace '(VALUE\s+"LegalCopyright",\s+"Copyright\s+\(C\)\s+)(\d{4})(\s+Nigerian Army Signal)', "`$1$currentYear`$3"
    
    # Write the updated content back to the file
    Set-Content -Path $rcFilePath -Value $updatedContent
    
    Write-Host "Copyright year updated successfully."
} else {
    Write-Host "Error: Runner.rc file not found at $rcFilePath"
    exit 1
}
