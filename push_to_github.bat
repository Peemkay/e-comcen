@echo off
echo Pushing changes to GitHub...

set PROJECT_DIR=C:\Users\chaki\Documents\Projects Augment\NASDS

cd "%PROJECT_DIR%"

echo.
echo Current Git Status:
git status

echo.
echo Adding all changes to staging...
git add .

echo.
echo Committing changes...
git commit -m "Fix TCL column time not updating on generated slips and update app icons"

echo.
echo Pushing changes to GitHub...
git push

echo.
echo Done!
pause
