@echo off
REM Script to fix flutter_bluetooth_serial namespace issue for Windows
REM This adds the missing namespace to the package's build.gradle

echo Fixing flutter_bluetooth_serial namespace issue...

set PACKAGE_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle

if exist "%PACKAGE_PATH%" (
    echo Found package at: %PACKAGE_PATH%

    REM Check if namespace already exists
    findstr /C:"namespace" "%PACKAGE_PATH%" >nul
    if %errorlevel% equ 0 (
        echo Namespace already exists. No changes needed.
    ) else (
        echo Adding namespace to build.gradle...

        REM Backup original file
        copy "%PACKAGE_PATH%" "%PACKAGE_PATH%.backup" >nul

        REM Create temporary file with namespace
        (
            for /f "delims=" %%i in (%PACKAGE_PATH%) do (
                echo %%i
                echo %%i | findstr /C:"android {" >nul
                if not errorlevel 1 (
                    echo     namespace 'io.github.edufolly.flutterbluetoothserial'
                )
            )
        ) > "%PACKAGE_PATH%.tmp"

        REM Replace original with modified version
        move /y "%PACKAGE_PATH%.tmp" "%PACKAGE_PATH%" >nul

        echo Namespace added successfully!
    )
) else (
    echo Error: Package not found at expected location.
    echo Please run 'flutter pub get' first.
    exit /b 1
)

echo Done! You can now build the app.
pause
