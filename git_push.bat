@echo off
echo Setting up Git configuration...
cd "C:\Users\chaki\Documents\Projects Augment\NASDS"

echo Configuring Git user email...
git config user.email "mubarakabubakarbako@gmail.com"

echo Checking remote repository...
git remote -v
if %ERRORLEVEL% NEQ 0 (
    echo Setting up remote repository...
    git remote add origin https://github.com/Peemkay/e-comcen.git
) else (
    echo Remote repository already set up.
)

echo Staging changes...
git add .

echo Committing changes...
git commit -m "Improved transit slip generator to match preview exactly"

echo Pushing to GitHub...
git push -u origin main

echo Done!
pause
