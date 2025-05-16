@echo off
echo ===================================================
echo NASDS Application Runner
echo ===================================================
echo.

REM Check if nasds.exe is already running
tasklist /fi "imagename eq nasds.exe" | find /i "nasds.exe" > nul
if %ERRORLEVEL% equ 0 (
    echo NASDS application is already running.
    echo.

    :choice
    set /p answer=Do you want to close the running instance and start a new one? (Y/N):
    if /i "%answer%"=="Y" (
        echo Closing running instance...
        taskkill /f /im nasds.exe
        echo.
        goto run_app
    ) else if /i "%answer%"=="N" (
        echo Operation cancelled.
        goto end
    ) else (
        echo Invalid choice. Please enter Y or N.
        goto choice
    )
) else (
    goto run_app
)

:run_app
echo.
echo Choose which application to run:
echo 1. Main NASDS Application
echo 2. NASDS Dispatcher Application
echo.
set /p app_choice=Enter your choice (1 or 2):

if "%app_choice%"=="1" (
    echo.
    echo Starting Main NASDS Application...
    echo.
    cd nasds
    flutter run -d windows
) else if "%app_choice%"=="2" (
    echo.
    echo Starting NASDS Dispatcher Application...
    echo.
    cd nasds
    flutter run -d windows --dart-define=APP_MODE=dispatcher
) else (
    echo.
    echo Invalid choice. Please run the script again and select 1 or 2.
    goto end
)

:end
echo.
echo ===================================================
echo.
pause
