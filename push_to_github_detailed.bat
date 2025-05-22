@echo off
setlocal enabledelayedexpansion

echo Pushing changes to GitHub...

set PROJECT_DIR=C:\Users\chaki\Documents\Projects Augment\NASDS

cd "%PROJECT_DIR%"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to change directory to %PROJECT_DIR%
    goto :error
)

echo.
echo Current Git Status:
git status
if %ERRORLEVEL% NEQ 0 (
    echo Failed to get git status
    goto :error
)

echo.
echo Adding all changes to staging...
git add .
if %ERRORLEVEL% NEQ 0 (
    echo Failed to add changes to staging
    goto :error
)

echo.
echo Committing changes...
git commit -m "Fix TCL column time not updating on generated slips and update app icons"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to commit changes
    goto :error
)

echo.
echo Pushing changes to GitHub...
git push
if %ERRORLEVEL% NEQ 0 (
    echo Failed to push changes to GitHub
    goto :error
)

echo.
echo Successfully pushed changes to GitHub!
goto :end

:error
echo.
echo An error occurred during the git operations.
echo Please check the error messages above.

:end
pause
