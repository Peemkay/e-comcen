# PowerShell script to push changes to GitHub
Write-Host "Pushing changes to GitHub..." -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

# Check if .git directory exists
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Cyan
    git init
    
    # Configure Git user
    git config user.name "Peemkay"
    git config user.email "mubarakabubakarbako@gmail.com"
    
    # Add GitHub remote
    git remote add origin https://github.com/Peemkay/e-comcen.git
} else {
    Write-Host "Git repository already initialized" -ForegroundColor Cyan
}

# Check current status
Write-Host "Current Git status:" -ForegroundColor Cyan
git status

# Add all files
Write-Host "Adding all files to Git..." -ForegroundColor Cyan
git add .

# Commit changes
$commitMessage = "Update app version to 1.0.0 and change Windows title to E-COMCEN"
Write-Host "Committing changes with message: $commitMessage" -ForegroundColor Cyan
git commit -m $commitMessage

# Push to GitHub
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git push -u origin master

Write-Host "Done!" -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
