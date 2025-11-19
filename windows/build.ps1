# Quickshell Bar Windows Build Script
# This script automatically builds the VirtualDesktopPlugin for Windows

param(
    [string]$QtPath = "C:\Qt\6.5.0\msvc2019_64",
    [switch]$Clean = $false
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"

function Write-ColorOutput($message, $color) {
    Write-Host $message -ForegroundColor $color
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as administrator
if (-not (Test-Admin)) {
    Write-ColorOutput "This script needs to be run as Administrator." $Red
    Write-ColorOutput "Please run: powershell -RunAs Administrator $PSCommandPath" $Yellow
    exit 1
}

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginDir = Join-Path $scriptDir "VirtualDesktopPlugin"
$buildDir = Join-Path $pluginDir "build"
$outputDir = Join-Path $scriptDir "VirtualDesktop"

Write-ColorOutput "========================================" $Green
Write-ColorOutput "Quickshell Bar Windows Build Script" $Green
Write-ColorOutput "========================================" $Green
Write-ColorOutput ""

# Check if Qt path exists
if (-not (Test-Path $QtPath)) {
    Write-ColorOutput "Error: Qt path not found at $QtPath" $Red
    Write-ColorOutput "Please specify the correct Qt path using -QtPath parameter" $Yellow
    Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.6.0\msvc2022_64'" $Yellow
    exit 1
}

Write-ColorOutput "Using Qt from: $QtPath" $Green
Write-ColorOutput ""

# Clean if requested
if ($Clean) {
    Write-ColorOutput "Cleaning build directory..." $Green
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
        Write-ColorOutput "Build directory cleaned." $Green
    }
}

# Create build directory if it doesn't exist
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-ColorOutput "Created build directory: $buildDir" $Green
}

# Change to build directory
Push-Location $buildDir

try {
    # Configure with CMake
    Write-ColorOutput "Configuring with CMake..." $Green
    $cmakeCommand = "cmake .. -G `"NMake Makefiles`" -DCMAKE_PREFIX_PATH=`"$QtPath`" -DCMAKE_BUILD_TYPE=Release"
    
    Invoke-Expression $cmakeCommand
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "CMake configuration failed!" $Red
        exit 1
    }
    
    Write-ColorOutput "CMake configuration completed successfully." $Green
    Write-ColorOutput ""
    
    # Build
    Write-ColorOutput "Building with NMake..." $Green
    nmake
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Build failed!" $Red
        exit 1
    }
    
    Write-ColorOutput "Build completed successfully." $Green
    Write-ColorOutput ""
    
    # Copy output files
    Write-ColorOutput "Copying files to output directory..." $Green
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    
    # Copy DLL
    $dllPath = Join-Path $buildDir "VirtualDesktopPlugin.dll"
    if (Test-Path $dllPath) {
        Copy-Item -Path $dllPath -Destination $outputDir -Force
        Write-ColorOutput "Copied DLL: $(Split-Path $dllPath -Leaf)" $Green
    } else {
        Write-ColorOutput "Warning: DLL not found at $dllPath" $Yellow
    }
    
    # Copy qmldir
    $qmldirSource = Join-Path $pluginDir "qmldir"
    if (Test-Path $qmldirSource) {
        Copy-Item -Path $qmldirSource -Destination $outputDir -Force
        Write-ColorOutput "Copied qmldir file" $Green
    }
    
    # Copy plugin.cpp and headers (for reference)
    $pluginCpp = Join-Path $pluginDir "plugin.cpp"
    if (Test-Path $pluginCpp) {
        Copy-Item -Path $pluginCpp -Destination $outputDir -Force
        Write-ColorOutput "Copied plugin.cpp" $Green
    }
    
    $headerFiles = Get-ChildItem -Path $pluginDir -Filter "*.h"
    foreach ($header in $headerFiles) {
        Copy-Item -Path $header.FullName -Destination $outputDir -Force
        Write-ColorOutput "Copied $(Split-Path $header.FullName -Leaf)" $Green
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "========================================" $Green
    Write-ColorOutput "Build Complete!" $Green
    Write-ColorOutput "========================================" $Green
    Write-ColorOutput ""
    Write-ColorOutput "Plugin files are located in:" $Green
    Write-ColorOutput "$outputDir" $Yellow
    Write-ColorOutput ""
    Write-ColorOutput "To run the application:" $Green
    Write-ColorOutput "`$env:QML2_IMPORT_PATH = `"$scriptDir`"" $Yellow
    Write-ColorOutput "qml .\windows.qml" $Yellow
    
} finally {
    # Return to original directory
    Pop-Location
}
