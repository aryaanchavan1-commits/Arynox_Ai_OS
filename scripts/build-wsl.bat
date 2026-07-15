@echo off
REM Arynox OS - WSL Build Launcher
REM Run this from Windows to build inside WSL2 Ubuntu

echo ========================================================
echo Arynox OS Build — WSL Launcher
echo ========================================================

REM Check WSL availability
wsl --status >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: WSL is not installed or configured.
    echo Please install WSL2 with Ubuntu 24.04:
    echo   wsl --install -d Ubuntu-24.04
    exit /b 1
)

REM Get the project path in Windows format
set PROJECT_DIR=%~dp0..
set BUILD_SCRIPT="%PROJECT_DIR%\scripts\build-iso.sh"

echo Project: %PROJECT_DIR%
echo Build script: %BUILD_SCRIPT%
echo.

REM Convert Windows path to WSL path
set WSL_PROJECT_DIR=/mnt/d/Arynoxtech/ArynoxOS

echo Starting WSL2 Ubuntu...

REM Start WSL and run the build
wsl -d Ubuntu --cd "%WSL_PROJECT_DIR%" -- bash scripts/build-iso.sh %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo Build FAILED. See errors above.
    exit /b 1
)

echo.
echo Build completed successfully!
echo ISO file is in: %PROJECT_DIR%\release\
dir "%PROJECT_DIR%\release\*.iso" 2>nul

pause
