@echo off
echo ===== GitHub Issue Diagnostic and Fix Tool =====
echo.

cd "C:\Users\chaki\Documents\Projects Augment\NASDS"

echo Checking Git installation...
git --version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git is not installed or not in PATH.
    echo Please install Git from https://git-scm.com/downloads
    pause
    exit /b 1
)

echo.
echo Checking Git configuration...
git config --list
echo.

echo Setting up Git user email...
git config user.email "mubarakabubakarbako@gmail.com"
echo Setting up Git user name...
git config user.name "Peemkay"

echo.
echo Checking remote repository...
git remote -v
if %ERRORLEVEL% NEQ 0 (
    echo Setting up remote repository...
    git remote add origin https://github.com/Peemkay/e-comcen.git
) else (
    echo Updating remote repository URL...
    git remote set-url origin https://github.com/Peemkay/e-comcen.git
)

echo.
echo Checking repository status...
git status

echo.
echo Checking for authentication issues...
echo If you're having authentication issues, you might need to use a personal access token.
echo Visit: https://github.com/settings/tokens to create a token.
echo.

echo Would you like to:
echo 1. Stage and commit changes
echo 2. Push to GitHub
echo 3. Both
echo 4. Exit
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto stage_commit
if "%choice%"=="2" goto push
if "%choice%"=="3" goto both
if "%choice%"=="4" goto end

:stage_commit
echo.
echo Staging changes...
git add .
echo.
echo Committing changes...
git commit -m "Improved transit slip generator to match preview exactly"
goto end

:push
echo.
echo Pushing to GitHub...
git push -u origin main
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Push failed. Trying alternative branch names...
    echo Trying 'master'...
    git push -u origin master
)
goto end

:both
echo.
echo Staging changes...
git add .
echo.
echo Committing changes...
git commit -m "Improved transit slip generator to match preview exactly"
echo.
echo Pushing to GitHub...
git push -u origin main
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Push failed. Trying alternative branch names...
    echo Trying 'master'...
    git push -u origin master
)
goto end

:end
echo.
echo Done!
pause
