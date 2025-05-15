$content = @'
# PowerShell Profile
# This file contains PowerShell profile settings

# Gradle aliases
Set-Alias -Name gradle -Value "C:\Users\chaki\Scripts\gradle-helper.ps1"
Set-Alias -Name g -Value "C:\Users\chaki\Scripts\gradle-helper.ps1"

# Function to run gradle build
function gbuild { & "C:\Users\chaki\Scripts\gradle-helper.ps1" build }

# Function to run gradle tasks
function gtasks { & "C:\Users\chaki\Scripts\gradle-helper.ps1" tasks }

# Function to run gradle clean
function gclean { & "C:\Users\chaki\Scripts\gradle-helper.ps1" clean }

# Function to run gradle test
function gtest { & "C:\Users\chaki\Scripts\gradle-helper.ps1" test }
'@

# Create the PowerShell profile directory if it doesn't exist
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -Path $profileDir -ItemType Directory
}

# Create the PowerShell profile
Set-Content -Path $PROFILE -Value $content

Write-Host "PowerShell profile has been created at $PROFILE" -ForegroundColor Green
