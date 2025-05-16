# Create Desktop Shortcuts for NASDS Application
# This script creates desktop shortcuts for the NASDS application

# Function to display colored text
function Write-ColorOutput {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Text -ForegroundColor $ForegroundColor
}

# Function to create a shortcut
function New-Shortcut {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ShortcutPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$IconLocation = "",
        
        [Parameter(Mandatory=$false)]
        [string]$WorkingDirectory = ""
    )
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.Description = $Description
        
        if ($WorkingDirectory -ne "") {
            $Shortcut.WorkingDirectory = $WorkingDirectory
        }
        
        if ($IconLocation -ne "") {
            $Shortcut.IconLocation = $IconLocation
        }
        
        $Shortcut.Save()
        return $true
    }
    catch {
        Write-ColorOutput "Error creating shortcut: $_" "Red"
        return $false
    }
}

# Main script execution
Clear-Host
Write-ColorOutput "===================================================" "Cyan"
Write-ColorOutput "        NASDS Desktop Shortcuts Creator            " "Green"
Write-ColorOutput "===================================================" "Cyan"
Write-Host ""

# Check if we're in the correct directory
if (-not (Test-Path -Path "$PSScriptRoot\nasds\lib\main.dart")) {
    Write-ColorOutput "Error: This script must be run from the NASDS root directory." "Red"
    Write-ColorOutput "Current directory: $PSScriptRoot" "Red"
    Write-ColorOutput "Expected to find: nasds\lib\main.dart" "Red"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Get the desktop path
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Create the batch file shortcut
$batchShortcutPath = "$desktopPath\NASDS Application.lnk"
$batchTargetPath = "$PSScriptRoot\run_nasds_complete.bat"
$batchDescription = "NASDS Application Launcher"
$batchWorkingDirectory = $PSScriptRoot

# Create the PowerShell shortcut
$psShortcutPath = "$desktopPath\NASDS Application (PowerShell).lnk"
$psTargetPath = "powershell.exe"
$psArguments = "-ExecutionPolicy Bypass -File `"$PSScriptRoot\run_nasds.ps1`""
$psDescription = "NASDS Application Launcher (PowerShell)"
$psWorkingDirectory = $PSScriptRoot

# Create shortcuts
Write-Host "Creating desktop shortcuts..."

# Create batch file shortcut
if (New-Shortcut -TargetPath $batchTargetPath -ShortcutPath $batchShortcutPath -Description $batchDescription -WorkingDirectory $batchWorkingDirectory) {
    Write-ColorOutput "Created batch file shortcut: $batchShortcutPath" "Green"
}
else {
    Write-ColorOutput "Failed to create batch file shortcut" "Red"
}

# Create PowerShell shortcut
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($psShortcutPath)
    $Shortcut.TargetPath = $psTargetPath
    $Shortcut.Arguments = $psArguments
    $Shortcut.Description = $psDescription
    $Shortcut.WorkingDirectory = $psWorkingDirectory
    $Shortcut.Save()
    Write-ColorOutput "Created PowerShell shortcut: $psShortcutPath" "Green"
}
catch {
    Write-ColorOutput "Error creating PowerShell shortcut: $_" "Red"
}

Write-Host ""
Write-ColorOutput "Desktop shortcuts creation completed." "Green"
Write-Host ""
Write-Host "You can now launch the NASDS application from your desktop."
Write-Host ""
Read-Host "Press Enter to exit"
