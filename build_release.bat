@echo off
echo Cleaning and building release version...
echo ==============================

cd /d "C:\Users\chaki\Documents\Projects Augment\NASDS"

echo Cleaning project...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo Building Windows release...
call flutter build windows --release

echo Done!
echo Press any key to exit...
pause
