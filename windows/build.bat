@echo off
REM Quickshell Bar Windows Build Script (CMD version)
REM This script automatically builds the VirtualDesktopPlugin for Windows

setlocal enabledelayedexpansion

REM Default Qt path
set QT_PATH=C:\Qt\6.5.0\msvc2019_64
set CLEAN_BUILD=0

REM Parse command line arguments
if "%1"=="/clean" (
    set CLEAN_BUILD=1
    if not "!%2"=="" set QT_PATH=!%2!
) else if not "!%1"=="" (
    set QT_PATH=!%1!
)

echo.
echo ========================================
echo Quickshell Bar Windows Build Script
echo ========================================
echo.

REM Check for admin rights (optional warning)
echo Checking prerequisites...
if not exist "%QT_PATH%" (
    echo Error: Qt path not found at %QT_PATH%
    echo.
    choice /M "Qt not found. Install Qt via vcpkg and continue?"
    if errorlevel 2 (
        echo Please specify the correct Qt path and re-run the script.
        echo   build.bat "C:\Qt\6.6.0\msvc2022_64"
        exit /b 1
    )

    echo Installing Qt via vcpkg (headless). This may take a long time...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host 'git required. Install git and retry.'; exit 1 }
        $v = 'C:\vcpkg'
        if (-not (Test-Path $v)) { git clone https://github.com/microsoft/vcpkg.git $v }
        if (-not (Test-Path (Join-Path $v 'vcpkg.exe'))) { & (Join-Path $v 'bootstrap-vcpkg.bat') }
        & (Join-Path $v 'vcpkg.exe') install qt6-base:x64-windows
    } catch { Write-Host 'vcpkg install failed: ' $_.Exception.Message; exit 1 }"

    if errorlevel 1 (
        echo vcpkg installation failed.
        exit /b 1
    )

    set VCPKG_ROOT=C:\vcpkg
    set VCPKG_TOOLCHAIN=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
    set QT_PATH=%VCPKG_ROOT%\installed\x64-windows
    set USE_VCPKG=1
    echo Set QT_PATH to %QT_PATH%
)

echo Using Qt from: %QT_PATH%
echo.

REM Get the script directory
set SCRIPT_DIR=%~dp0
set PLUGIN_DIR=%SCRIPT_DIR%VirtualDesktopPlugin
set BUILD_DIR=%PLUGIN_DIR%\build
set OUTPUT_DIR=%SCRIPT_DIR%VirtualDesktop

REM Clean if requested
if %CLEAN_BUILD%==1 (
    echo Cleaning build directory...
    if exist "%BUILD_DIR%" (
        rmdir /s /q "%BUILD_DIR%"
        echo Build directory cleaned.
    )
)

REM Create build directory
if not exist "%BUILD_DIR%" (
    mkdir "%BUILD_DIR%"
    echo Created build directory: %BUILD_DIR%
)

REM Change to build directory
cd /d "%BUILD_DIR%"
if errorlevel 1 (
    echo Error: Failed to change to build directory
    exit /b 1
)

REM Configure with CMake
echo.
echo Configuring with CMake...
if defined USE_VCPKG (
    cmake .. -G "NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE="%VCPKG_TOOLCHAIN%" -DVCPKG_TARGET_TRIPLET="x64-windows" -DCMAKE_BUILD_TYPE=Release
    if errorlevel 1 (
        echo CMake configuration failed!
        exit /b 1
    )
) else (
    cmake .. -G "NMake Makefiles" -DCMAKE_PREFIX_PATH="%QT_PATH%" -DCMAKE_BUILD_TYPE=Release
    if errorlevel 1 (
        echo CMake configuration failed!
        exit /b 1
    )
)

echo CMake configuration completed successfully.
echo.

REM Build
echo Building with NMake...
nmake
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Build completed successfully.
echo.

REM Copy output files
echo Copying files to output directory...

REM Create output directory if needed
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
)

REM Copy DLL
if exist "%BUILD_DIR%\VirtualDesktopPlugin.dll" (
    copy "%BUILD_DIR%\VirtualDesktopPlugin.dll" "%OUTPUT_DIR%\" /y
    echo Copied DLL: VirtualDesktopPlugin.dll
) else (
    echo Warning: DLL not found at %BUILD_DIR%\VirtualDesktopPlugin.dll
)

REM Copy qmldir
if exist "%PLUGIN_DIR%\qmldir" (
    copy "%PLUGIN_DIR%\qmldir" "%OUTPUT_DIR%\" /y
    echo Copied qmldir file
)

REM Copy headers and source files
if exist "%PLUGIN_DIR%\plugin.cpp" (
    copy "%PLUGIN_DIR%\plugin.cpp" "%OUTPUT_DIR%\" /y
    echo Copied plugin.cpp
)

for /r "%PLUGIN_DIR%" %%F in (*.h) do (
    copy "%%F" "%OUTPUT_DIR%\" /y
    echo Copied %%~nxF
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Plugin files are located in:
echo %OUTPUT_DIR%
echo.
echo To run the application:
echo   set QML2_IMPORT_PATH=%SCRIPT_DIR%
echo   qml windows.qml
echo.

cd /d "%SCRIPT_DIR%"
endlocal
